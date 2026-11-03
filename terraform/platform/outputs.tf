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

output "namespace" {
  description = "Kubernetes namespace hosting the application"
  value       = kubernetes_namespace_v1.platform.metadata[0].name
}

output "deployment_name" {
  description = "Name of the application deployment"
  value       = kubernetes_deployment_v1.application.metadata[0].name
}

output "application_replicas" {
  description = "Desired number of application replicas"
  value       = kubernetes_deployment_v1.application.spec[0].replicas
}

output "application_image" {
  description = "Docker image used by the application"
  value       = var.application_image
}

output "application_service" {
  description = "Internal Kubernetes service name"
  value       = kubernetes_service_v1.application.metadata[0].name
}

output "application_service_cluster_ip" {
  description = "Internal ClusterIP assigned to the application"
  value       = kubernetes_service_v1.application.spec[0].cluster_ip
}