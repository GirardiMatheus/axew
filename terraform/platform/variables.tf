variable "kubeconfig_path" {
  description = "Path to the Kubernetes kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubernetes context used by Terraform"
  type        = string
  default     = "kind-axew"
}

variable "application_image" {
  description = "Docker image used by the Axew application"
  type        = string
  default     = "axew-api:1.0"
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2

  validation {
    condition     = var.replicas >= 1 && var.replicas <= 5
    error_message = "Replicas must be between 1 and 5."
  }
}