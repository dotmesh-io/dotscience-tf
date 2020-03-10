output "DotscienceHub_URL" {
  value = "https://${local.hub_hostname}"
}

output "Grafana_URL" {
  value = local.grafana_host
}

output "CLI_env_file" {
  value = "source .ds_env.sh"
}
