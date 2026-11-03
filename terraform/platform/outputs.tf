output "kubernetes_context" {
  description = "Kubernetes context used by Terraform"
  value       = var.kubernetes_context
}

output "kubeconfig_path" {
  description = "Path to the Kubernetes kubeconfig file"
  value       = pathexpand(var.kubeconfig_path)
}

output "default_namespace" {
  description = "Name of the existing default namespace"
  value       = data.kubernetes_namespace_v1.default.metadata[0].name
}