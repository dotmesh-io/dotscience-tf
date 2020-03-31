
output "hub_public_url" {
  value = join("", ["https://", local.hub_hostname])
}

output "hub_public_ip" {
  value = local.hub_ip
}

output "hub_instance_name" {
  value = google_compute_instance.dotscience_hub_vm.name
}

output "grafana_host" {
  value = module.ds_monitoring.grafana_host
}

output "models_served_under" {
  value = local.deployer_model_subdomain
}

output "gke_cluster_name" {
  value = "dotscience-deployer-${random_id.default.hex}"
}

output "CLI_env_file" {
  value = "source .ds_env.sh"
}
