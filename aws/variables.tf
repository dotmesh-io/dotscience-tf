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

variable "letsencrypt_ingress_cidr" {
  description = "The CIDR block for connections coming into the Hub from https://letsencrypt.org/. Let's encrypt servers do not have a whitelist IP set. Set value to '' to restrict all access."
  default     = "0.0.0.0/0"
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

variable "eks_cluster_worker_count" {
  default = 2
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

variable "dotscience_domain" {
  description = "Domain name that you control, in which to deploy dotscience Hub to, eg. dotscience.example-corp.com. Currently defaults to a wildcard DNS server that is maintained by Dotscience"
  default     = "your.dots.ci"
}

variable "model_deployment_domain" {
  description = "Domain name that you control the name servers for, into which model deployments go into. See docs https://docs.dotscience.com/install/tf-aws/"
  default     = "your.dots.ci"
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

variable "model_deployment_mode" {
  description = "Set to 'aws-ga' to host models on model-abc.1-2-3-4.your.dots.ci or 'route53' to host models on model-abc.your.domain.com"
  default     = "aws-ga"

  validation {
    condition     = var.model_deployment_mode == "aws-ga" || var.model_deployment_mode == "route53"
    error_message = "Set to 'aws-ga' to host models on model-abc.1-2-3-4.your.dots.ci or 'route53' to host models on model-abc.your.domain.com."
  }
}
