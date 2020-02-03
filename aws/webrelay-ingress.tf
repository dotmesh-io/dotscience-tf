resource "kubernetes_namespace" "webrelay_ingress" {
  metadata {
    name = "webrelay-ingress"
  }
}

resource "kubernetes_service_account" "webrelay" {
  metadata {
    name      = "webrelay"
    namespace = "webrelay-ingress"
  }
}

resource "kubernetes_deployment" "webrelay" {
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

          env {
            name  = "RELAY_NAME"
            value = "hosted-dotscience"
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
