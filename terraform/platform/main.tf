data "kubernetes_namespace_v1" "default" {
  metadata {
    name = "default"
  }
}