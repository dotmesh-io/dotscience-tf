# Prom + Grafana
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
}


