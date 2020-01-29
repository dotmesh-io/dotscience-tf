resource "kubernetes_service" "grafana_lb" {
  metadata {
    name = "external-grafana"
  }
  spec {
    selector = {
      app = "grafana"

    }
    session_affinity = "ClientIP"
    port {
      name        = "app"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name = "grafana"
  }

  data = {
    admin-user = var.grafana_admin_user
    admin-password = var.grafana_admin_password
  }

  type= "Opaque"
}

resource "helm_release" "prometheus" {
  name  = "prometheus"
  chart = "stable/prometheus"

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

resource "helm_release" "grafana" {
  name  = "grafana"
  chart = "stable/grafana"

  depends_on = [
    kubernetes_secret.grafana_admin
  ]

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "admin.existingSecret"
    value = "grafana"
  }
}

output "grafana_host" {
  value = kubernetes_service.grafana_lb.load_balancer_ingress[0].ip
}

