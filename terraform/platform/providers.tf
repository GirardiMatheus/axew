terraform {
  required_version = ">= 1.9.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3.0"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = var.kubernetes_context
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand("~/.kube/config")
    config_context = "kind-axew"
  }
}