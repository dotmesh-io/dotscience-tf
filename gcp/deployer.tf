resource "kubernetes_namespace" "dotscience_deployer" {
  metadata {
    name = "dotscience-deployer"
  }
}

resource "kubernetes_service_account" "dotscience_deployer" {
  metadata {
    name      = "dotscience-deployer"
    namespace = "dotscience-deployer"

    labels = {
      app = "dotscience-deployer"
    }
  }
}

resource "kubernetes_cluster_role" "dotscience_deployer" {
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
            value = "${local.hub_hostname}:8800"
          }

          env {
            name  = "TOKEN"
            value = random_id.deployer_token.hex
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

