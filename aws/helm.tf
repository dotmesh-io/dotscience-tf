# Give tiller a service account with cluster-admin role.
# See https://github.com/terraform-providers/terraform-provider-helm/issues/77

# Also https://github.com/hashicorp/terraform/issues/21008#issuecomment-531496335
# for why we name the role binding the same as the service account... to avoid
# destroy failing due to destroying things in the wrong order and failing

provider "helm" {
  # service_account = kubernetes_cluster_role_binding.tiller.metadata.0.name
  # namespace       = kubernetes_service_account.tiller.metadata.0.namespace
  # install_tiller  = true
  # Same creds as we hand to the kubernetes provider in eks.tf
  kubernetes {
    host                   = element(concat(data.aws_eks_cluster.cluster[*].endpoint, list("")), 0)
    cluster_ca_certificate = base64decode(element(concat(data.aws_eks_cluster.cluster[*].certificate_authority.0.data, list("")), 0))
    token                  = element(concat(data.aws_eks_cluster_auth.cluster[*].token, list("")), 0)
    load_config_file       = false
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = kubernetes_service_account.tiller.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller.metadata.0.name
    namespace = kubernetes_service_account.tiller.metadata.0.namespace
  }
}
