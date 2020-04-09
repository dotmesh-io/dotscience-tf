variable "hub_public_url" {
  description = "URL of hub"
  type        = string
}

variable "hub_admin_password" {
  description = "password of hub"
  type        = string
}

variable "runners_depends_on" {
  type = any
}