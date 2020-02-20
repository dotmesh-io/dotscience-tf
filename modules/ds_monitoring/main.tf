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
    load_config_file       = false
  }
  version = "1.0.0"
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "kubernetes_service" "grafana_lb" {
  count = var.create_monitoring ? 1 : 0

  metadata {
    name = "external-grafana"
  }
  spec {
    selector = {
      "app.kubernetes.io/name" = "grafana"
    }
    port {
      name        = "app"
      port        = 80
      target_port = 3000
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
  depends_on = [helm_release.grafana]
}

resource "kubernetes_secret" "grafana_admin" {
  count = var.create_monitoring ? 1 : 0

  metadata {
    name = "grafana"
  }

  data = {
    admin-user     = var.grafana_admin_user
    admin-password = var.grafana_admin_password
  }

  type = "Opaque"
}

resource "helm_release" "prometheus" {
  count = var.create_monitoring ? 1 : 0

  name       = "prometheus"
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/prometheus"
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

resource "helm_release" "grafana" {
  count = var.create_monitoring ? 1 : 0

  name       = "grafana"
  repository = data.helm_repository.stable.metadata[0].name
  chart = "stable/grafana"
  timeout = 300

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

  set {
    name  = "ingress.enabled"
    value = "true"
  }
}

locals {
  grafana_host = var.dotscience_environment == "aws" ? "http://${element(concat(kubernetes_service.grafana_lb[*].load_balancer_ingress[0].hostname, list("")), 0)}/" : "http://${element(concat(kubernetes_service.grafana_lb[*].load_balancer_ingress[0].ip, list("")), 0)}/"
}

provider "grafana" {
  url  = local.grafana_host
  auth = "${var.grafana_admin_user}:${var.grafana_admin_password}"
}

resource "grafana_data_source" "prometheus" {
  count      = var.create_monitoring ? 1 : 0
  type       = "prometheus"
  name       = "prometheus"
  url        = "http://prometheus-server/"
  is_default = true

  depends_on = [kubernetes_service.grafana_lb]
}
