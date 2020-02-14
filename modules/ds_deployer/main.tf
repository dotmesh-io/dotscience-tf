resource "random_id" "default" {
  byte_length = 8
}


provider "kubernetes" {
  host                   = var.kubernetes_host
  cluster_ca_certificate = var.cluster_ca_certificate
  token                  = var.kubernetes_token
  load_config_file       = false
  version                = "~> 1.9"
}

provider "helm" {
  kubernetes {
    host                   = var.kubernetes_host
    cluster_ca_certificate = var.cluster_ca_certificate
    token                  = var.kubernetes_token
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
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

        service_account_name            = "dotscience-deployer"
        automount_service_account_token = true
      }
    }
  }
}

resource "helm_release" "nginx-ingress" {
  # count = var.create_deployer ? 1 : 0

  name  = "nginx-ingress"
  repository = data.helm_repository.stable.metadata[0].name
  chart = "stable/nginx-ingress"
  timeout = 300

  set {
    name  = "controller.containerPort.http"
    value = "80"
  }
}

resource "kubernetes_service" "ingress_lb" {
  # count = var.create_deployer ? 1 : 0

  depends_on = [
    helm_release.nginx-ingress
  ]

  metadata {
    name = "external-ingress"
    labels = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "ingress-nginx"
      "app.kubernetes.io/part-of" = "ingress-nginx"
    }
    session_affinity = "ClientIP"
    port {
      name        = "app"
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

locals {
  ingress_host = kubernetes_service.ingress_lb.load_balancer_ingress[0].ip
}

output "ingress_host" {
  value = local.ingress_host
}