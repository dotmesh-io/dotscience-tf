output "DotscienceHub_IP" {
  value = "http://${aws_eip.ds_eip.public_ip}"
}

output "DotscienceHub_URL" {
  value = "https://${local.hub_hostname}"
}