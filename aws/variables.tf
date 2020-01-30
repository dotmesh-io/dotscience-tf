variable "dotscience_version" {
  description = "Version information for this build that released this Terraform configuration"
  type        = string
  default     = "DotScience devel 2020-01-21 16-26-19 aa3a1651b07b471bffd103fb5e23f4b04d6a8ba3"
}

variable "region" {
  default = "us-east-1"
}

variable "project" {
  description = "Name of project, used for identifying resources"
  type        = string
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

variable "az_number" {
  # Assign a number to each AZ letter used in our configuration
  default = {
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
    f = 6
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

variable "hub_ec2_instance_name" {
  description = "Hub EC2 Instance Name"
  default     = "DotscienceHub"
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
variable "runner_ec2_instance_name" {
  description = "Runner EC2 Instance Name"
  default     = "DotscienceRunner"
  type        = string
}
variable "runner_volume_size" {
  description = "The storage volume size in GB used for the Dotscience Runner. Must be larger than 128."
  type        = number
  default     = 1024
}
variable "runner_instance_type" {
  description = "Runner EC2 instance type"
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
    #    {
    #      rolearn  = "arn:aws:iam::66666666666:role/role1"
    #      username = "role1"
    #      groups   = ["system:masters"]
    #    },
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
    #    {
    #      userarn  = "arn:aws:iam::66666666666:user/user1"
    #      username = "user1"
    #      groups   = ["system:masters"]
    #    },
    #    {
    #      userarn  = "arn:aws:iam::66666666666:user/user2"
    #      username = "user2"
    #      groups   = ["system:masters"]
    #    },
  ]
}