
output "hub_public_url" {
  value = join("", ["https://", local.hub_hostname])
}

output "hub_instance_name" {
  value = google_compute_instance.dotscience_hub_vm.name
}

output "grafana_host" {
  value = module.ds_monitoring.grafana_host
}
