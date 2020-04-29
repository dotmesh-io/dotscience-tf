variable "dotscience_environment" {
  description = "Dotscience environment such as 'gcp', 'aws'"
  type        = string
}

variable hub_hostname {
  description = "Hostname of the Dotscience Hub, the deployer uses this to connect to the Hub"
  type        = string
}

variable "create_deployer" {
  description = "Toggle for conditionally creating the deployer"
  type        = string
}

variable "deployer_token" {
  description = "Unqiue token that is used for the deployer"
  type        = string
}

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

variable "model_deployment_mode" {
  description = "Set to 'aws-ga' to host models on model-abc.1-2-3-4.your.dotscience.com or 'route53' to host models on model-abc.your.domain.com"
  default     = "aws-ga"
}
