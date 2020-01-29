variable "dotscience_version" {
  description = "Version information for this build that released this Terraform configuration"
  type = string
  default = "DotScience devel 2020-01-21 16-26-19 aa3a1651b07b471bffd103fb5e23f4b04d6a8ba3"
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

variable "stack_name" {
}

variable "amis" {
  type = map
  default = {
    "us-east-1" : {
      "Hub" : "ami-0438340d48f1ecf2b",
      "CPURunner" : "ami-059b4ecdb5d31f499",
      "GPURunner" : "ami-0e8c502966ca4cc57"
    }
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

variable "grafana_user" {
  description = "The admin username for the Grafana server, used for Dotscience Hub monitoring"
  type        = string
  default     = ""
}

variable "grafana_password" {
  description = "The password for the Grafana admin user, used for Dotscience Hub monitoring"
  type        = string
  default     = ""
}
