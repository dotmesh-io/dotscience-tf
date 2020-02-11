
resource "helm_release" "nginx-ingress" {
  name  = "nginx-ingress"
  chart = "stable/nginx-ingress"
  timeout = 300

  set {
    name  = "server.global.scrape_interval"
    value = "10s"
  }

  set {
    name  = "server.global.scrape_timeout"
    value = "5s"
  }

  set {
    name  = "server.persistentVolume.size"
    value = "50Gi"
  }
}

resource "kubernetes_service" "ingress_lb" {
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