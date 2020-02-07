# locals {
#     grafana_admin_user = var.grafana_admin_user
#     grafana_admin_password = var.grafana_admin_password
# }


# resource "kubernetes_service" "grafana_lb" {
#   metadata {
#     name = "external-grafana"
#   }
#   spec {
#     selector = {
#       app = "grafana"

#     }
#     session_affinity = "ClientIP"
#     port {
#       name        = "app"
#       port        = 80
#       target_port = 3000
#       protocol    = "TCP"
#     }

#     type = "LoadBalancer"
#   }
# }

# resource "kubernetes_secret" "grafana_admin" {
#   metadata {
#     name = "grafana"
#   }

#   data = {
#     admin-user = local.grafana_admin_user
#     admin-password = local.grafana_admin_password
#   }

#   type= "Opaque"
# }

# resource "helm_release" "prometheus" {
#   name  = "prometheus"
#   chart = "stable/prometheus"

#   set {
#     name  = "server.global.scrape_interval"
#     value = "10s"
#   }

#   set {
#     name  = "server.global.scrape_timeout"
#     value = "5s"
#   }

#   set {
#     name  = "server.persistentVolume.size"
#     value = "50Gi"
#   }
# }

# resource "helm_release" "grafana" {
#   name  = "grafana"
#   chart = "stable/grafana"

#   depends_on = [
#     kubernetes_secret.grafana_admin
#   ]

#   set {
#     name  = "persistence.enabled"
#     value = "true"
#   }

#   set {
#     name  = "admin.existingSecret"
#     value = "grafana"
#   }
# }

# locals {
#   grafana_host = kubernetes_service.grafana_lb.load_balancer_ingress[0].ip
# }

# provider "grafana" {
#   url  = "http://${local.grafana_host}/"
#   auth = "${local.grafana_admin_user}:${local.grafana_admin_password}"
# }

# resource "grafana_data_source" "prometheus" {
#   type          = "prometheus"
#   name          = "prometheus"
#   url           = "http://prometheus-server/"
#   is_default    = true
# }

# Give tiller a service account with cluster-admin role.
# See https://github.com/terraform-providers/terraform-provider-helm/issues/77

# Also https://github.com/hashicorp/terraform/issues/21008#issuecomment-531496335
# for why we name the role binding the same as the service account... to avoid
# destroy failing due to destroying things in the wrong order and failing

# provider "helm" {
#   service_account = kubernetes_cluster_role_binding.tiller.metadata.0.name
#   namespace       = kubernetes_service_account.tiller.metadata.0.namespace
#   install_tiller  = true
#   # Same creds as we hand to the kubernetes provider in eks.tf
#   kubernetes {
#     host = google_container_cluster.dotscience_deployer.endpoint
#     token = data.google_client_config.default.access_token
#     cluster_ca_certificate = base64decode(google_container_cluster.dotscience_deployer.master_auth.0.cluster_ca_certificate)
#     load_config_file = false
#   }
# }

# resource "kubernetes_service_account" "tiller" {
#   metadata {
#     name      = "tiller"
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_cluster_role_binding" "tiller" {
#   metadata {
#     name = kubernetes_service_account.tiller.metadata.0.name
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.tiller.metadata.0.name
#     namespace = kubernetes_service_account.tiller.metadata.0.namespace
#   }
# }
