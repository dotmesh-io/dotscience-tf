resource "google_container_cluster" "dotscience_deployer" {
  name     = "dotscience-deployer"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = "admin"
    password = "flibbetywidget_olive_underneath_triangle"

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  cluster_autoscaling {
    enabled = true
    resource_limits {
        resource_type = "cpu"
        minimum = 200
        maximum = 1600
    }
    resource_limits {
        resource_type = "memory"
        minimum = 2
        maximum = 16
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "dotscience-deployer-node-pool"
  location   = var.region
  cluster    = google_container_cluster.dotscience_deployer.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }
}

provider "kubernetes" {
  host = google_container_cluster.dotscience_deployer.endpoint
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.dotscience_deployer.master_auth.0.cluster_ca_certificate)
  load_config_file = false
}
