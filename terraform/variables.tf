variable "kube_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
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

variable "storage_class" {
  description = "Storage class to use for persistent volumes"
  type        = string
  default     = "local-path"  # Default for local k8s deployments
}

variable "indexer_storage_size" {
  description = "Storage size for Wazuh indexer"
  type        = string
  default     = "30Gi"
}

variable "manager_storage_size" {
  description = "Storage size for Wazuh manager"
  type        = string
  default     = "10Gi"
}

variable "wazuh_chart_version" {
  description = "Version of the Wazuh Helm chart"
  type        = string
  default     = "4.7.0"  # Update to the latest version as needed
}

variable "wazuh_values_file" {
  description = "Path to the Wazuh Helm values file"
  type        = string
  default     = "../helm_charts/wazuh-values.yaml"
}