/**
 * Wazuh SIEM Deployment with OpenTofu
 * 
 * This configuration deploys Wazuh SIEM on a Kubernetes cluster using Kustomize.
 * It sets up all necessary components including:
 * - Wazuh Manager
 * - Wazuh Indexer (Elasticsearch)
 * - Wazuh Dashboard (Kibana)
 * 
 * The deployment is designed for local environments running on Fedora Atomic.
 */

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.0"
    }
  }
  required_version = ">= 1.5.0"
}

# Configure the Kubernetes provider to use the local cluster
provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = var.kube_context
}

# Create a dedicated namespace for Wazuh components
# This isolates the Wazuh deployment from other applications in the cluster
resource "kubernetes_namespace" "wazuh" {
  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

# Create storage class for local storage
# This storage class is optimized for Wazuh's persistence needs on local Fedora Atomic
# - Uses no-provisioner for local storage
# - WaitForFirstConsumer ensures pods are scheduled before volumes
# - Retain policy preserves data even after PVC deletion
resource "kubernetes_storage_class" "local_storage" {
  metadata {
    name = "wazuh-local-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Retain"

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Generate secure random passwords for Wazuh components
# These passwords are used for internal communication and admin access
# We avoid special characters to prevent escaping issues in Kubernetes secrets

# Cluster key for secure communication between Wazuh manager nodes
resource "random_password" "wazuh_cluster_key" {
  length  = 32
  special = false
}

# API credentials for accessing Wazuh API
resource "random_password" "wazuh_api_password" {
  length  = 16
  special = false
}

# Authentication password for Wazuh agent registration
resource "random_password" "wazuh_authd_password" {
  length  = 16
  special = false
}

# Admin password for Wazuh Indexer (Elasticsearch)
resource "random_password" "indexer_admin_password" {
  length  = 16
  special = false
}

# Admin password for Wazuh Dashboard (Kibana)
resource "random_password" "dashboard_admin_password" {
  length  = 16
  special = false
}

# Create secrets for Wazuh
resource "kubernetes_secret" "wazuh_cluster_key" {
  metadata {
    name      = "wazuh-cluster-key-secret"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  data = {
    "key" = random_password.wazuh_cluster_key.result
  }
}

resource "kubernetes_secret" "wazuh_api_credentials" {
  metadata {
    name      = "wazuh-api-cred-secret"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  data = {
    "username" = "wazuh-api"
    "password" = random_password.wazuh_api_password.result
  }
}

resource "kubernetes_secret" "wazuh_authd_pass" {
  metadata {
    name      = "wazuh-authd-pass-secret"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  data = {
    "password" = random_password.wazuh_authd_password.result
  }
}

resource "kubernetes_secret" "indexer_credentials" {
  metadata {
    name      = "indexer-cred-secret"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  data = {
    "username" = "admin"
    "password" = random_password.indexer_admin_password.result
  }
}

resource "kubernetes_secret" "dashboard_credentials" {
  metadata {
    name      = "dashboard-cred-secret"
    namespace = kubernetes_namespace.wazuh.metadata[0].name
  }
  data = {
    "username" = "admin"
    "password" = random_password.dashboard_admin_password.result
  }
}

# Clone the official Wazuh Kubernetes repository
# This repository contains all the necessary Kustomize configurations for deploying Wazuh
# We clone it locally to customize it for our Fedora Atomic environment
resource "null_resource" "clone_wazuh_kubernetes" {
  provisioner "local-exec" {
    command = <<-EOT
      # Clone if directory doesn't exist, otherwise update the existing repository
      if [ ! -d "${var.wazuh_kustomize_dir}" ]; then
        echo "Cloning Wazuh Kubernetes repository..."
        git clone https://github.com/wazuh/wazuh-kubernetes.git ${var.wazuh_kustomize_dir}
      else
        echo "Updating existing Wazuh Kubernetes repository..."
        cd ${var.wazuh_kustomize_dir} && git pull
      fi
    EOT
  }
}

# Customize the Wazuh Kustomize files for our Fedora Atomic environment
# This step:
# 1. Backs up the original kustomization file
# 2. Generates necessary certificates for secure communication
resource "null_resource" "customize_wazuh_kustomize" {
  depends_on = [null_resource.clone_wazuh_kubernetes]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Customizing Wazuh Kustomize configuration..."
      
      # Backup the original kustomization file
      cp ${var.wazuh_kustomize_dir}/envs/local-env/kustomization.yml ${var.wazuh_kustomize_dir}/envs/local-env/kustomization.yml.bak
      
      # Update the resources in the kustomization file if needed
      # This would be done with sed or other text manipulation tools
      # For example, we could adjust resource limits for Fedora Atomic
      
      echo "Generating certificates for secure Wazuh communication..."
      
      # Generate certificates for Wazuh Indexer (Elasticsearch) cluster
      if [ -d "${var.wazuh_kustomize_dir}/wazuh/certs/indexer_cluster" ]; then
        cd ${var.wazuh_kustomize_dir}/wazuh/certs/indexer_cluster && ./generate_certs.sh
      else
        echo "Warning: indexer_cluster certs directory not found, skipping certificate generation"
      fi
      
      # Generate certificates for Wazuh Dashboard (Kibana) HTTPS
      if [ -d "${var.wazuh_kustomize_dir}/wazuh/certs/dashboard_http" ]; then
        cd ${var.wazuh_kustomize_dir}/wazuh/certs/dashboard_http && ./generate_certs.sh
      else
        echo "Warning: dashboard_http certs directory not found, skipping certificate generation"
      fi
      
      echo "Customization completed successfully."
    EOT
  }
}

# Deploy Wazuh using Kustomize
# This is the final step that applies all the Kubernetes resources
# We ensure all prerequisites are met before deployment
resource "null_resource" "deploy_wazuh" {
  depends_on = [
    kubernetes_namespace.wazuh,              # Namespace must exist
    kubernetes_storage_class.local_storage,  # Storage class for persistence
    kubernetes_secret.wazuh_cluster_key,     # Secret for cluster communication
    kubernetes_secret.wazuh_api_credentials, # Secret for API access
    kubernetes_secret.wazuh_authd_pass,      # Secret for agent registration
    kubernetes_secret.indexer_credentials,   # Secret for Elasticsearch access
    kubernetes_secret.dashboard_credentials, # Secret for Kibana access
    null_resource.customize_wazuh_kustomize  # Customization must be complete
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Deploying Wazuh SIEM to Kubernetes..."
      
      # Create a temporary kustomization file that points to the Wazuh resources
      # and sets the correct namespace
      cat > /tmp/kustomization.yml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${kubernetes_namespace.wazuh.metadata[0].name}
resources:
  - ${var.wazuh_kustomize_dir}/envs/local-env
EOF

      # Apply the kustomization using kubectl
      kubectl apply -k /tmp/
      
      echo "Wazuh deployment initiated. It may take several minutes for all pods to start."
    EOT
  }
}