variable "region" {
  type    = string
  default = "us-east1"
}

variable "zone" {
  type    = string
  default = "us-east1-b"
}

variable "project" {
  description = "GCP project id"
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

variable "hub_instance_name" {
  description = "Hub Instance Name"
  default     = "DotscienceHub"
  type        = string
}

variable "hub_volume_size" {
  description = "The storage volume size in GB used for the Dotscience Hub. Must be larger than 128."
  type        = number
  default     = 1024
}

variable "hub_instance_type" {
  description = "Hub instance type"
  type        = string
  default     = "n1-standard-1"
}

variable "license_key" {
  description = "Dotscience License Key, get one from https://licensing.dotscience.com"
  type        = string
}

variable "letsencrypt_mode" {
  description = "Let's Encrypt mode, choose one of 'off' (don't attempt to get TLS cert at all), 'staging' (use letsencrypt staging server, good for tests), 'production' (get real TLS cert for hub hostname). Note that we (Dotscience) provide a xip.io-like service at hub-1-2-3-4.your.dotscience.net so that even without setting up DNS, you'll get a TLS-enabled hub endpoint given just a public IPv4 address for your hub"
  type        = string
  default     = "off"
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

variable "webrelay_key" {
  description = "Key from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  type = string
}

variable "webrelay_secret" {
  description = "Secret from https://my.webhookrelay.com/tokens (temporarily while we migrate to in-cluster relay)"
  type = string
}

variable "runner_machine_type" {
  description = "Default managed runner machine type e.g. n1-standard-2"
  default = "n1-standard-2"
  type = "string"
}
