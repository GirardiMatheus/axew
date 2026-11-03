variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "axew"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers and hyphens."
  }
}

variable "node_image" {
  description = "Kind node image used for the Kubernetes cluster"
  type        = string
  default     = "kindest/node:v1.34.0"
}

variable "worker_count" {
  description = "Number of Kubernetes worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "Worker count must be between 1 and 3."
  }
}

variable "kubeconfig_path" {
  description = "Path where the Kubernetes kubeconfig will be stored"
  type        = string
  default     = "~/.kube/config"
}