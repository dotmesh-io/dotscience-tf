provider "google" {
  project = var.project
  region = var.region
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
  // TODO make it easier for a devops team using this tf to change the
  // your.dotscience.net reference, probably by having a var which overrides
  // this builtin hostname
  hub_hostname = join("", ["hub-", replace(google_compute_address.hub_ipv4_address.address, ".", "-"), ".your.dotscience.net"])
  zone         = "${var.region}-b"
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "dotscience_hub_vm" {
 name         = "dotscience-hub-vm-${random_id.default.hex}"
 machine_type = "n1-standard-1"
 zone         = local.zone

 boot_disk {
   initialize_params {
     image = "dotscience-images/dotscience-hub-1580339885"
   }
 }

 metadata_startup_script = <<-EOF
#!/bin/bash -xe
echo "Starting Dotscience hub"
/home/ubuntu/startup.sh --admin-password "${var.admin_password}" --cloud gcp --hub-size "${var.hub_volume_size}" --hub-device /dev/sdb --hub-hostname "${local.hub_hostname}" --use-kms=false --license-key="${var.license_key}" --letsencrypt-mode="${var.letsencrypt_mode}" --gcp-runner-project "${var.project}" --gcp-runner-zone "${local.zone}" --deployer-token "${random_id.deployer_token.hex}"
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

output "hub_public_url" {
  value = join("", ["https://", local.hub_hostname])
}

output "hub_instance_name" {
  value = google_compute_instance.dotscience_hub_vm.name
}

resource "google_compute_disk" "dotscience_hub_disk" {
  name  = "dotscience-hub-disk-${random_id.default.hex}"
  type  = "pd-ssd"
  zone  = local.zone
  size  = 100
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
        days_in_cycle  = 1
        start_time     = "23:00"
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
      guest_flush       = true
    }
  }
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.dotscience_hub_disk.self_link
  instance = google_compute_instance.dotscience_hub_vm.self_link
}

resource "google_compute_firewall" "dotscience_firewall" {
  name    = "dotscience-firewall-${random_id.default.hex}"
  network = google_compute_network.dotscience_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8800", "22"]
  }

  //source_tags = ["web"]
}

resource "google_compute_network" "dotscience_network" {
  name = "dotscience-network-${random_id.default.hex}"
}

