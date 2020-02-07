variable "create_monitoring" {
  description = "Toggle for conditionally creating the monitoring services"
  type = string
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