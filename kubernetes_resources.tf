resource "kubernetes_namespace" "ns" {
  metadata {
    name = "test1"
  }
}
