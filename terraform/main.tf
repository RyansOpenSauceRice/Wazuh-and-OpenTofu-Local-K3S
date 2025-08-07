terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kube_config_path
    config_context = var.kube_context
  }
}

# Create a namespace for Wazuh
resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

# Create persistent volumes for Wazuh components
resource "kubernetes_persistent_volume_claim" "wazuh_indexer" {
  metadata {
    name      = "wazuh-indexer-data"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.indexer_storage_size
      }
    }
    storage_class_name = var.storage_class
  }
}

resource "kubernetes_persistent_volume_claim" "wazuh_manager" {
  metadata {
    name      = "wazuh-manager-data"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.manager_storage_size
      }
    }
    storage_class_name = var.storage_class
  }
}

# Deploy Wazuh using Helm
resource "helm_release" "wazuh" {
  name       = "wazuh"
  repository = "https://wazuh.github.io/helm"
  chart      = "wazuh"
  version    = var.wazuh_chart_version
  namespace  = kubernetes_namespace.wazuh.metadata[0].name

  values = [
    file(var.wazuh_values_file)
  ]

  depends_on = [
    kubernetes_namespace.wazuh,
    kubernetes_persistent_volume_claim.wazuh_indexer,
    kubernetes_persistent_volume_claim.wazuh_manager
  ]
}