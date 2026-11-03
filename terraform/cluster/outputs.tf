output "cluster_name" {
  description = "Name of the provisioned Kubernetes cluster"
  value       = kind_cluster.axew.name
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = kind_cluster.axew.endpoint
}

output "kubeconfig_path" {
  description = "Path to the generated kubeconfig"
  value       = pathexpand(var.kubeconfig_path)
}

output "kubectl_context" {
  description = "Kubectl context associated with the Kind cluster"
  value       = "kind-${kind_cluster.axew.name}"
}

output "worker_count" {
  description = "Number of provisioned worker nodes"
  value       = var.worker_count
}