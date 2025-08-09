variable "kube_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
  # Alternative paths that might work if the default doesn't:
  # - "/etc/rancher/k3s/k3s.yaml" (k3s default location)
  # - "/tmp/kubeconfig" (symlink created by setup.sh)
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "default"
}

variable "namespace" {
  description = "Kubernetes namespace for Wazuh deployment"
  type        = string
  default     = "wazuh"
}

variable "environment" {
  description = "Environment label for the deployment"
  type        = string
  default     = "local"
}

# Commented out as currently unused - will be used in future versions
# variable "storage_class" {
#   description = "Storage class to use for persistent volumes"
#   type        = string
#   default     = "wazuh-local-storage"
# }

variable "wazuh_kustomize_dir" {
  description = "Directory where the Wazuh Kubernetes repository will be cloned"
  type        = string
  default     = "../../wazuh-kubernetes"
}

# Commented out as currently unused - will be used in future versions
# variable "wazuh_kubernetes_version" {
#   description = "Version/branch of the Wazuh Kubernetes repository to use"
#   type        = string
#   default     = "main"
# }

# Resource limits for Wazuh components
# These variables are currently unused but will be implemented in future versions
# for configuring resource limits in the Kubernetes deployment

# Wazuh master node resources
# variable "master_cpu_request" {
#   description = "CPU request for Wazuh master node"
#   type        = string
#   default     = "500m"
# }
# 
# variable "master_memory_request" {
#   description = "Memory request for Wazuh master node"
#   type        = string
#   default     = "1Gi"
# }
# 
# variable "master_cpu_limit" {
#   description = "CPU limit for Wazuh master node"
#   type        = string
#   default     = "1"
# }
# 
# variable "master_memory_limit" {
#   description = "Memory limit for Wazuh master node"
#   type        = string
#   default     = "2Gi"
# }

# Wazuh worker node resources
# variable "worker_cpu_request" {
#   description = "CPU request for Wazuh worker node"
#   type        = string
#   default     = "500m"
# }
# 
# variable "worker_memory_request" {
#   description = "Memory request for Wazuh worker node"
#   type        = string
#   default     = "1Gi"
# }
# 
# variable "worker_cpu_limit" {
#   description = "CPU limit for Wazuh worker node"
#   type        = string
#   default     = "1"
# }
# 
# variable "worker_memory_limit" {
#   description = "Memory limit for Wazuh worker node"
#   type        = string
#   default     = "2Gi"
# }

# Wazuh indexer resources
# variable "indexer_cpu_request" {
#   description = "CPU request for Wazuh indexer"
#   type        = string
#   default     = "500m"
# }
# 
# variable "indexer_memory_request" {
#   description = "Memory request for Wazuh indexer"
#   type        = string
#   default     = "1Gi"
# }
# 
# variable "indexer_cpu_limit" {
#   description = "CPU limit for Wazuh indexer"
#   type        = string
#   default     = "1"
# }
# 
# variable "indexer_memory_limit" {
#   description = "Memory limit for Wazuh indexer"
#   type        = string
#   default     = "2Gi"
# }

# Wazuh dashboard resources
# variable "dashboard_cpu_request" {
#   description = "CPU request for Wazuh dashboard"
#   type        = string
#   default     = "250m"
# }
# 
# variable "dashboard_memory_request" {
#   description = "Memory request for Wazuh dashboard"
#   type        = string
#   default     = "512Mi"
# }
# 
# variable "dashboard_cpu_limit" {
#   description = "CPU limit for Wazuh dashboard"
#   type        = string
#   default     = "500m"
# }
# 
# variable "dashboard_memory_limit" {
#   description = "Memory limit for Wazuh dashboard"
#   type        = string
#   default     = "1Gi"
# }