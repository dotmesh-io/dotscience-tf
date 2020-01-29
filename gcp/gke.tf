resource "google_container_cluster" "dotscience_deployer" {
  name     = "dotscience-deployer-${random_id.default.hex}"
  location = var.region

  initial_node_count       = 1

  master_auth {
    username = "admin"
    password = "flibbetywidget_olive_underneath_triangle"

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

provider "kubernetes" {
  host = google_container_cluster.dotscience_deployer.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.dotscience_deployer.master_auth.0.cluster_ca_certificate)
  load_config_file = false
}
