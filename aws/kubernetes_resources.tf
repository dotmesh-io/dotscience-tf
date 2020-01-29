provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}

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
      name = "app"
      port        = 80
      target_port = 3000
      protocol = "TCP"
    }

    type = "LoadBalancer"
  }
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

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "adminUser"
    value = var.grafana_admin_user
  }

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}
