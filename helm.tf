# Give tiller a service account with cluster-admin role.
# See https://github.com/terraform-providers/terraform-provider-helm/issues/77

resource "kubernetes_service_account" "tiller_service_account" {
  metadata {
    name = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller_cluster_role_binding" {
  metadata {
    name = "tiller"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller_service_account.metadata.0.name
    namespace = "kube-system"
  }
}

provider "helm" {
  service_account = kubernetes_service_account.tiller_service_account.metadata.0.name
  # Same creds as we hand to the kubernetes provider in eks.tf
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}
