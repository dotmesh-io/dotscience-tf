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

locals {
  grafana_host = kubernetes_service.grafana_lb.load_balancer_ingress[0].ip
}

output "grafana_host" {
  value = local.grafana_host
}

provider "grafana" {
  url  = "http://${local.grafana_host}/"
  auth = "${var.grafana_admin_user}:${var.grafana_admin_password}"
}

resource "grafana_data_source" "prometheus" {
  type          = "prometheus"
  name          = "prometheus"
  url           = "http://prometheus-server/"
  is_default    = true
}
