variable "dotscience_aws_version" {
  description = "Version information for this build that released this Terraform configuration"
}

variable "region" {
  description = "AWS region in which Dotscience will be provisioned in"
  default     = "us-east-1"
}

variable "aws_role_arn" {
  description = "AWS role ARN for Terraform to use to assume Role into. Format arn:aws:iam::account-id:role/role-name"
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instances"
}

variable "admin_password" {
  description = "The login password for the initial admin user"
}

variable "vpc_network_cidr" {
  description = "The CIDR block for the entire VPC network"
  default     = "10.0.0.0/16"
}

variable "ssh_access_cidrs" {
  description = "The CIDR block that can connect via SSH"
}

variable "hub_ingress_cidrs" {
  description = "The CIDR block for connections coming into the Hub"
}

variable "model_ingress_cidrs" {
  description = "The CIDR block for allowed connections to hosted models"
  default     = ["0.0.0.0/0"]
}

variable "letsencrypt_ingress_cidrs" {
  description = "The CIDR block for connections coming into the Hub from https://letsencrypt.org/. Let's encrypt servers do not have a whitelist IP set. Set value to '' to restrict all access."
  default     = ["0.0.0.0/0"]
}

variable "remote_runner_ingress_cidrs" {
  description = "The CIDR list for connections coming into the Hub from remote runners, specifically those not provisioned by AWS."
  default     = []
}

variable "hub_volume_size" {
  description = "The storage volume size in GB used for the Dotscience Hub. Must be larger than 128."
  type        = number
  default     = 1024
}
variable "hub_instance_type" {
  description = "Hub EC2 instance type"
  default     = "m5.2xlarge"
}

variable "grafana_host" {
  description = "The hostname of the Grafana server, used for Dotscience Hub monitoring"
  default     = ""
}

variable "grafana_admin_user" {
  description = "The password for the Grafana admin user, used for Dotscience Hub monitoring"
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "The password for the Grafana admin user, used for Dotscience Hub monitoring"
}

variable "eks_cluster_worker_instance_type" {
  default = "t3.small"
}

variable "eks_cluster_worker_count" { //Must be atleast 3 to cover all subnets in a region.
  default = 3
}

variable "amis" {
  type = map
}

variable "dotscience_startup_version" {
}

variable "letsencrypt_mode" {
  type = string
}

variable "license_key" {
  description = "Dotscience License Key"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default = [
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
  ]
}

variable "webrelay_key" {
  description = "Key from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  default     = "b06e261f-074e-47b5-bfbe-4d6d94ccd6f4"
}

variable "webrelay_secret" {
  description = "Secret from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  default     = "4rAW5vq0D7uN"
}

variable "create_eks" {
  description = "Toggle to create an EKS cluster for the dotscience model deployments"
  default     = "true"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint for model deployments"
  default = [
    "0.0.0.0/0"
  ]
}

variable "create_deployer" {
  description = "Toggle to create a default dotscience deployer on the above mentioned EKS cluster, requires create_eks to be set to true"
  default     = "true"
}

variable "create_monitoring" {
  description = "Toggle to create monitoring services for model deployed on the default deployer, requires create_eks and create_deployer to be set to true"
  default     = "true"
}

variable "environment" {
  description = "Set to development for tagging resources with caller_identity"
  default     = "ds"
}

variable "dotscience_domain" {
  description = "Domain name that you control, in which to deploy dotscience Hub to, eg. dotscience.example-corp.com. Setting this to 'your.dotscience.com' sets up Dotscience Hub on ip-address.your.dotscience.com. Set this to a Route53 domain that you control to enable route53 based DNS"
  default     = "your.dotscience.net"
}

variable "tls_config_mode" {
  description = "TLS configuration can be set to 'http' or 'dns_route53'. Setting this to 'http' uses Let's encrypt HTTP challenge to get SSL certs, setting this to 'dns_route53' uses Let's encrypt DNS-01 challenge to get SSL certs"
  default     = "http"
}

variable "associate_public_ip" {
  description = "Associate a public IP address to the Dotscience Hub instance, setting this to true creates an EIP that routes requests to this instance."
  default     = true
}

