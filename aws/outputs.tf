output "hub_public_url" {
  value = join("", ["https://", local.hub_hostname])
}

output "hub_public_ip" {
  value = local.hub_ip
}

output "grafana_host" {
  value = local.grafana_host
}

output "models_served_under" {
  value = local.deployer_model_subdomain
}

output "model_eip" {
  value = aws_eip.ds_model_eip[0].public_ip
}

output "cli_env_file" {
  value = "source .ds_env.sh"
}
