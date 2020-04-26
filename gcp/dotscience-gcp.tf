provider "google" {
  project = var.project
  region  = var.region
}

provider "kubernetes" {
  host                   = element(concat(google_container_cluster.dotscience_deployer[*].endpoint, list("")), 0)
  token                  = element(concat(data.google_client_config.default[*].access_token, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(google_container_cluster.dotscience_deployer[*].master_auth.0.cluster_ca_certificate, list("")), 0))
  load_config_file       = false
  version                = "~> 1.11.1"
}

data "google_client_config" "default" {
}

// Terraform plugin for creating random ids
resource "random_id" "default" {
  byte_length = 8
}

resource "random_id" "deployer_token" {
  byte_length = 16
}

locals {
  hub_hostname             = join("", ["hub-", replace(google_compute_address.hub_ipv4_address.address, ".", "-"), ".", var.dotscience_domain])
  hub_ip                   = google_compute_address.hub_ipv4_address.address
  deployer_model_subdomain = var.create_deployer && var.create_gke ? join("", [".models-", replace(element(concat(module.ds_deployer.ingress_host, list("")), 0), ".", "-"), ".", var.dotscience_domain]) : ""
  zone                     = var.zone
  deployer_token           = random_id.deployer_token.hex
  grafana_host             = var.create_monitoring && var.create_gke ? module.ds_monitoring.grafana_host : ""
}

module "ds_deployer" {
  source                 = "../modules/ds_deployer"
  create_deployer        = var.create_deployer && var.create_gke ? 1 : 0
  hub_hostname           = local.hub_hostname
  deployer_token         = local.deployer_token
  kubernetes_host        = element(concat(google_container_cluster.dotscience_deployer[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(google_container_cluster.dotscience_deployer[*].master_auth.0.cluster_ca_certificate, list("")), 0))
  kubernetes_token       = element(concat(data.google_client_config.default[*].access_token, list("")), 0)
  dotscience_environment = "gcp"
}

module "ds_monitoring" {
  source                 = "../modules/ds_monitoring"
  create_monitoring      = var.create_monitoring && var.create_gke && var.create_deployer ? 1 : 0
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
  kubernetes_host        = element(concat(google_container_cluster.dotscience_deployer[*].endpoint, list("")), 0)
  cluster_ca_certificate = base64decode(element(concat(google_container_cluster.dotscience_deployer[*].master_auth.0.cluster_ca_certificate, list("")), 0))
  kubernetes_token       = element(concat(data.google_client_config.default[*].access_token, list("")), 0)
  dotscience_environment = "gcp"
}

# data "http" "gcp-machine-image" {
#   url = "https://storage.googleapis.com/dotscience-amis/latest/hub-gcp-image-d552006adc14485a722bf1910b3b2048adab75fa.tfvars.json"
# }

resource "google_container_cluster" "dotscience_deployer" {
  count    = var.create_gke ? 1 : 0
  name     = "${var.environment}-deployer-${random_id.default.hex}"
  location = local.zone

  // XXX TODO switch to using a node pool so we don't have to destroy the whole cluster if we change it
  // https://www.terraform.io/docs/providers/google/r/container_cluster.html#node_pool

  initial_node_count = 3

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

// A single Google Cloud Engine instance
resource "google_compute_instance" "dotscience_hub_vm" {
  name         = "dotscience-hub-vm-${random_id.default.hex}"
  machine_type = "n1-standard-1"
  zone         = local.zone

  boot_disk {
    initialize_params {
      image = "dotscience-images/${var.id}"
    }
  }

  metadata_startup_script = <<-EOF
#!/bin/bash -xe
echo "Starting Dotscience hub"

sudo wget -O /usr/local/bin/ds-startup https://storage.googleapis.com/dotscience-startup/${var.dotscience_startup_version}/ds-startup

sudo chmod +wx /usr/local/bin/ds-startup

ds-startup --admin-password "${var.admin_password}" --cloud gcp --hub-size "${var.hub_volume_size}" --hub-device /dev/sdb --hub-hostname "${local.hub_hostname}" --use-kms=false --license-key="${var.license_key}" --letsencrypt-mode="${var.letsencrypt_mode}" --gcp-runner-project "${var.project}" --gcp-runner-zone "${local.zone}" --gcp-runner-machine-type "${var.runner_machine_type}" --deployer-token "${random_id.deployer_token.hex}" --grafana-user "${var.grafana_admin_user}" --grafana-host "${local.grafana_host}"  --grafana-password "${var.grafana_admin_password}" --deployment-ingress-class "nginx" --deployment-subdomain "${local.deployer_model_subdomain}"
EOF
  network_interface {
    network = google_compute_network.dotscience_network.name

    access_config {
      nat_ip = google_compute_address.hub_ipv4_address.address
    }
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }
  service_account {
    // TODO: scope this down further, power broker probably just needs to be
    // able to create and destroy VMs (and maybe disks)
    scopes = ["cloud-platform"]
  }
  allow_stopping_for_update = true

}

resource "google_compute_address" "hub_ipv4_address" {
  name = "dotscience-hub-ipv4-address-${random_id.default.hex}"
}

resource "google_compute_disk" "dotscience_hub_disk" {
  name     = "dotscience-hub-disk-${random_id.default.hex}"
  type     = "pd-ssd"
  zone     = local.zone
  size     = var.hub_volume_size
  snapshot = var.restore_from_backup

  lifecycle {
    # Prevent destruction of the hub disk if data loss is not permitted.
    prevent_destroy = !var.permit_data_loss
  }

}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name = google_compute_resource_policy.dotscience_hub_disk_backups.name
  disk = google_compute_disk.dotscience_hub_disk.name
  zone = local.zone
}

resource "google_compute_resource_policy" "dotscience_hub_disk_backups" {
  name   = "dotscience-hub-disk-backups-${random_id.default.hex}"
  region = var.region
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "23:00"
      }
    }
    retention_policy {
      max_retention_days    = 30
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      labels = {
        dotscience_hub_backup = "true"
      }
      guest_flush = true
    }
  }
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.dotscience_hub_disk.self_link
  instance = google_compute_instance.dotscience_hub_vm.self_link
}

resource "google_compute_firewall" "dotscience_firewall" {
  name    = "dotscience-ingress-firewall-${random_id.default.hex}"
  network = google_compute_network.dotscience_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    // Port 80   - Access to the Dotscience Hub web UI
    // Port 443  - Access to the Dotscience Hub web UI with TLS
    // Port 8800 - Dotscience API gateway
    // Port 9800 - Dotscience webhook relay transponder connections
    ports = ["80", "443", "8800", "9800"]
  }

  source_ranges = var.hub_ingress_cidrs
}

resource "google_compute_firewall" "dotscience_ssh_firewall" {
  name    = "dotscience-ssh-firewall-${random_id.default.hex}"
  network = google_compute_network.dotscience_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    // Port 22   - Provides ssh access to the dotscience runner, for debugging 
    ports = ["22"]
  }

  source_ranges = var.ssh_access_cidrs
}

resource "google_compute_network" "dotscience_network" {
  name = "dotscience-network-${random_id.default.hex}"
}

resource "local_file" "ds_env_file" {
  content  = "export DOTSCIENCE_USERNAME=admin\nexport DOTSCIENCE_PASSWORD=${var.admin_password}\nexport DOTSCIENCE_URL=https://${local.hub_hostname}"
  filename = ".ds_env.sh"
}
