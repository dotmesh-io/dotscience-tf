variable "dotscience_aws_version" {
  description = "Version information for this build that released this Terraform configuration"
  type        = string
}

variable "region" {
  default = "us-east-1"
}

variable "region_number" {
  # Arbitrary mapping of region name to number to use in
  # a VPC's CIDR prefix.
  default = {
    us-east-1      = 1
    us-west-1      = 2
    us-west-2      = 3
    eu-central-1   = 4
    ap-northeast-1 = 5
  }
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the instances"
  type        = string
}

variable "admin_password" {
  description = "The login password for the initial admin user"
  type        = string
}

variable "vpc_network_cidr" {
  description = "The CIDR block for the entire VPC network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ssh_access_cidr" {
  description = "The CIDR block that can connect via SSH"
  type        = string
}


variable "hub_ingress_cidr" {
  description = "The CIDR block for connections coming into the Hub"
  type        = string
}

variable "hub_volume_size" {
  description = "The storage volume size in GB used for the Dotscience Hub. Must be larger than 128."
  type        = number
  default     = 1024
}
variable "hub_instance_type" {
  description = "Hub EC2 instance type"
  type        = string
  default     = "m5.2xlarge"
}

variable "grafana_host" {
  description = "The hostname of the Grafana server, used for Dotscience Hub monitoring"
  type        = string
  default     = ""
}

variable "grafana_admin_user" {
  description = "The password for the Grafana admin user, used for Dotscience Hub monitoring"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "The password for the Grafana admin user, used for Dotscience Hub monitoring"
  type        = string
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

variable "letsencrypt_mode" {
  type = string
}

variable "license_key" {
  description = "Dotscience License Key"
  type        = string
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    #    "777777777777",
    #    "888888888888",
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
  description = "Domain name that you control, in which to deploy dotscience to, eg. dotscience.example-corp.com"
  type        = string
  default     = "your.dotscience.net"
}

variable "webrelay_key" {
  description = "Key from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  type        = string
  default     = "b06e261f-074e-47b5-bfbe-4d6d94ccd6f4"
}

variable "webrelay_secret" {
  description = "Secret from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  type        = string
  default     = "4rAW5vq0D7uN"
}

variable "create_eks" {
  description = "Secret from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  type        = string
  default     = "true"
}

variable "create_deployer" {
  description = "Toggle to create a default dotscience deployer on the above mentioned GKE cluster, requires create_gke to be set to true"
  type        = string
  default     = "true"
}

variable "create_monitoring" {
  description = "Toggle to create monitoring services for model deployed on the default deployer, requires create_gke and create_deployer to be set to true"
  type        = string
  default     = "true"
}