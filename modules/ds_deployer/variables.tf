variable hub_hostname {
  description = "Hostname of the Dotscience Hub, the deployer uses this to connect to the Hub"
  type        = string
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

variable "create_deployer" {
  description = "Toggle for conditionally creating the deployer"
  type        = string
}

variable "deployer_token" {
  description = "Unqiue token that is used for the deployer"
  type        = string
}

# variable "deployer_model_subdomain" {
#   description = "Subdomain that you control for the models to use, in a form of '.models.example.com'"
#   type        = string
# }

variable "kubernetes_host" {
  description = "Unqiue token that is used for the deployer"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Certificate to auth into the kubernetes cluster"
  type        = string
}

variable "kubernetes_token" {
  description = "Token to auth into the kubernetes cluster"
  type        = string
}