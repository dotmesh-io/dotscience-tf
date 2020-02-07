resource "random_id" "default" {
 byte_length = 8
}

resource "kubernetes_namespace" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "dotscience-deployer"
  }
}

resource "kubernetes_service_account" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name      = "dotscience-deployer"
    namespace = "dotscience-deployer"

    labels = {
      app = "dotscience-deployer"
    }
  }
}

resource "kubernetes_cluster_role" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "dotscience-deployer"
  }

  rule {
    verbs      = ["watch", "list"]
    api_groups = [""]
    resources  = ["namespaces"]
  }

  rule {
    verbs      = ["get", "create", "delete", "watch", "list", "update"]
    api_groups = ["", "extensions", "apps"]
    resources  = ["deployments", "services", "ingresses", "secrets", "pods", "pods/log"]
  }
}

resource "kubernetes_cluster_role_binding" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "dotscience-deployer"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "dotscience-deployer"
    namespace = "dotscience-deployer"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "dotscience-deployer"
  }
}

resource "kubernetes_service" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0
  metadata {
    name      = "dotscience-deployer"
    namespace = "dotscience-deployer"

    labels = {
      app = "dotscience-deployer"
    }
  }

  spec {
    port {
      name        = "dotscience-deployer"
      protocol    = "TCP"
      port        = 9300
      target_port = "9300"
    }

    selector = {
      app = "dotscience-deployer"
    }

    type             = "LoadBalancer"
    session_affinity = "None"
  }
}

resource "kubernetes_deployment" "dotscience_deployer" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name      = "dotscience-deployer"
    namespace = "dotscience-deployer"

    labels = {
      app = "dotscience-deployer"
    }

    annotations = {
      "keel.sh/policy" = "force"

      "keel.sh/pollSchedule" = "@every 1m"

      "keel.sh/trigger" = "poll"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dotscience-deployer"
      }
    }

    template {
      metadata {
        labels = {
          app = "dotscience-deployer"
        }
      }

      spec {
        container {
          name    = "deployer"
          image   = "quay.io/dotmesh/dotscience-deployer:latest"
          command = ["ds-deployer", "run"]

          port {
            container_port = 9300
          }

          env {
            name = "NAMESPACE"

            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name  = "GATEWAY_ADDRESS"
            value = "${var.hub_hostname}:8800"
          }

          env {
            name  = "TOKEN"
            value = var.deployer_token
          }

          env {
            name  = "HEALTH_PORT"
            value = "9300"
          }

          resources {
            limits {
              cpu    = "600m"
              memory = "512Mi"
            }

            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "9300"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 10
          }

          image_pull_policy = "Always"
        }

        service_account_name = "dotscience-deployer"
        automount_service_account_token = true
      }
    }
  }
}

resource "kubernetes_namespace" "webrelay_ingress" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "webrelay-ingress"
  }
}

resource "kubernetes_service_account" "webrelay" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name      = "webrelay"
    namespace = "webrelay-ingress"
  }
}

resource "kubernetes_deployment" "webrelay" {
  count = var.create_deployer ? 1 : 0

  depends_on = [
    kubernetes_secret.webrelay_credentials
  ]
  metadata {
    name      = "webrelay"
    namespace = "webrelay-ingress"

    labels = {
      app = "webrelay"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "webrelay"
      }
    }

    template {
      metadata {
        labels = {
          app = "webrelay"
        }
      }

      spec {
        container {
          name    = "webrelay"
          image   = "docker.io/webrelay/ingress:latest"
          command = ["reingress"]
          args    = ["server", "--incluster"]

          env {
            name = "RELAY_NAME"
            value = random_id.default.hex
          }

          env {
            name = "RELAY_KEY"

            value_from {
              secret_key_ref {
                name = "webrelay-credentials"
                key  = "key"
              }
            }
          }

          env {
            name = "RELAY_SECRET"

            value_from {
              secret_key_ref {
                name = "webrelay-credentials"
                key  = "secret"
              }
            }
          }
          image_pull_policy = "Always"
        }

        termination_grace_period_seconds = 10
        dns_policy                       = "ClusterFirst"
        service_account_name             = "webrelay"
        automount_service_account_token  = true
      }
    }
  }
}

resource "kubernetes_cluster_role_binding" "webrelay" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "webrelay"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "webrelay"
    namespace = "webrelay-ingress"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "webrelay"
  }
}

resource "kubernetes_cluster_role" "webrelay" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "webrelay"
  }

  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods"]
  }

  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["nodes"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services"]
  }

  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }
}

resource "kubernetes_secret" "webrelay_credentials" {
  count = var.create_deployer ? 1 : 0

  metadata {
    name = "webrelay-credentials"
    namespace = "webrelay-ingress"
  }

  data = {
    key = var.webrelay_key
    secret = var.webrelay_secret
  }

  type = "Opaque"
}
