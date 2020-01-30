resource "google_container_cluster" "dotscience_deployer" {
  name     = "dotscience-deployer-${random_id.default.hex}"
  location = local.zone

  // XXX TODO switch to using a node pool so we don't have to destroy the whole cluster if we change it
  // https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool

  initial_node_count       = 3

  node_config {
    machine_type = "n1-standard-2"
  }

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
