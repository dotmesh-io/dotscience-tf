resource "random_string" "hub_suffix" {
  length  = 8
  special = false
}

resource "aws_cloudformation_stack" "dotscience-hub" {
  name = "dotscience-hub-${random_string.suffix.result}"
  # Created this template_url by first creating a bucket:
  #   aws s3 mb s3://dotscience-cf-templates
  # Then going to https://gitlab.dotmesh.com/dotmesh/dotscience-aws-sync/pipelines and clicking publish_manual on the latest pipeline.
  #   wget https://get.dotmesh.io/dotscience-aws/3ebcf7933c3685ab04ed67e50195c7843f2d6665/dotscience-cf.json
  #   aws s3 cp dotscience-cf.json s3://dotscience-cf-templates/dotscience-cf-3ebcf7933c3685ab04ed67e50195c7843f2d6665.json

  template_url = "https://s3.amazonaws.com/dotscience-cf-templates/dotscience-cf-3ebcf7933c3685ab04ed67e50195c7843f2d6665.json"
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    KeyName = var.dotscience_hub_ssh_key
    HubIngressCIDR = var.dotscience_hub_ingress_cidr
    SSHAccessCIDR = var.dotscience_ssh_access_cidr
    AdminPassword = var.dotscience_hub_admin_password
    HubInstanceType = var.dotscience_hub_instance_type
    HubVolumeSize = var.dotscience_hub_volume_size_gb
  }
}
