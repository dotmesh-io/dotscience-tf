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

variable "runner_machine_type" {
  description = "Default managed runner machine type e.g. n1-standard-2"
  default     = "n1-standard-2"
  type        = string
}

variable "dotscience_domain" {
  description = "Domain name that you control, in which to deploy dotscience to, eg. dotscience.example-corp.com"
  type        = string
  default     = "your.dotscience.net"
}

variable "create_gke" {
  description = "Toggle to create a GKE cluster, this cluster is used for dotscience deployments and monitoring"
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