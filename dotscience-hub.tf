resource "aws_cloudformation_stack" "dotscience-hub" {
  name = "dotscience-hub"
  # Created this template_url by first creating a bucket:
  #   aws s3 mb s3://dotscience-cf-templates
  # Then going to https://gitlab.dotmesh.com/dotmesh/dotscience-aws-sync/pipelines and clicking publish_manual on the latest pipeline.
  #   wget https://get.dotmesh.io/dotscience-aws/1f6a73da40822d800bf5b8b590235598ef94cb04/dotscience-cf.json
  #   aws s3 cp dotscience-cf.json s3://dotscience-cf-templates/dotscience-cf-1f6a73da40822d800bf5b8b590235598ef94cb04.json

  template_url = "https://s3.amazonaws.com/dotscience-cf-templates/dotscience-cf-1f6a73da40822d800bf5b8b590235598ef94cb04.json"
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
