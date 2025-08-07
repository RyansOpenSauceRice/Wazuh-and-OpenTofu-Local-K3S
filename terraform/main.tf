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

provider "kubernetes" {
  config_path    = var.kube_config_path
  config_context = var.kube_context
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

# Create storage class for local storage
resource "kubernetes_storage_class" "local_storage" {
  metadata {
    name = "wazuh-local-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  volume_binding_mode = "WaitForFirstConsumer"
  reclaim_policy      = "Retain"
}

# Generate random passwords for Wazuh components
resource "random_password" "wazuh_cluster_key" {
  length  = 32
  special = false
}

resource "random_password" "wazuh_api_password" {
  length  = 16
  special = false
}

resource "random_password" "wazuh_authd_password" {
  length  = 16
  special = false
}

resource "random_password" "indexer_admin_password" {
  length  = 16
  special = false
}

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

# Clone the Wazuh Kubernetes repository
resource "null_resource" "clone_wazuh_kubernetes" {
  provisioner "local-exec" {
    command = <<-EOT
      if [ ! -d "${var.wazuh_kustomize_dir}" ]; then
        git clone https://github.com/wazuh/wazuh-kubernetes.git ${var.wazuh_kustomize_dir}
      else
        cd ${var.wazuh_kustomize_dir} && git pull
      fi
    EOT
  }
}

# Copy and customize the Wazuh Kustomize files
resource "null_resource" "customize_wazuh_kustomize" {
  depends_on = [null_resource.clone_wazuh_kubernetes]

  provisioner "local-exec" {
    command = <<-EOT
      # Copy the local environment kustomization file
      cp ${var.wazuh_kustomize_dir}/envs/local-env/kustomization.yml ${var.wazuh_kustomize_dir}/envs/local-env/kustomization.yml.bak
      
      # Update the resources in the kustomization file if needed
      # This would be done with sed or other text manipulation tools
      
      # Create certificates for Wazuh components
      cd ${var.wazuh_kustomize_dir}/wazuh/certs/indexer_cluster && ./generate_certs.sh
      cd ${var.wazuh_kustomize_dir}/wazuh/certs/dashboard_http && ./generate_certs.sh
    EOT
  }
}

# Deploy Wazuh using Kustomize
resource "null_resource" "deploy_wazuh" {
  depends_on = [
    kubernetes_namespace.wazuh,
    kubernetes_storage_class.local_storage,
    kubernetes_secret.wazuh_cluster_key,
    kubernetes_secret.wazuh_api_credentials,
    kubernetes_secret.wazuh_authd_pass,
    kubernetes_secret.indexer_credentials,
    kubernetes_secret.dashboard_credentials,
    null_resource.customize_wazuh_kustomize
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Create a temporary kustomization file
      cat > /tmp/kustomization.yml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${kubernetes_namespace.wazuh.metadata[0].name}
resources:
  - ${var.wazuh_kustomize_dir}/envs/local-env
EOF

      # Apply the kustomization
      kubectl apply -k /tmp/
    EOT
  }
}