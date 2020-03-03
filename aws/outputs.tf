output "DotscienceHub_IP" {
  value = "http://${aws_eip.ds_eip.public_ip}"
}

output "DotscienceHub_URL" {
  value = "https://${local.hub_hostname}"
}

output "Grafana_URL" {
  value = local.grafana_host
}

output "CLI_env_file" {
  value = "source .ds_env.sh"
}

output "Deployer_Name_Servers" {
  value = aws_route53_zone.model_deployments.name_servers
}