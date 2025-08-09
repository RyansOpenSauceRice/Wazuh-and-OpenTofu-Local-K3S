#!/bin/bash
# error_handler.sh - Handles errors and provides recovery procedures

# Script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source path resolver
# shellcheck source=./path_resolver.sh disable=SC1091
source "${SCRIPT_DIR}/path_resolver.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_DIR="${REPO_ROOT}/logs"
LOG_FILE="${LOG_DIR}/deployment.log"

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"

# Function to print colored messages
print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

# Function to log messages
log_message() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

# Function to handle errors
handle_error() {
  local error_code="$1"
  local error_message="$2"
  local recovery_function="$3"

  print_message "${RED}" "ERROR: ${error_message} (Code: ${error_code})"
  log_message "ERROR" "${error_message} (Code: ${error_code})"

  if [ -n "${recovery_function}" ] && [ "$(type -t "${recovery_function}")" = "function" ]; then
    print_message "${YELLOW}" "Attempting recovery..."
    log_message "INFO" "Attempting recovery with function: ${recovery_function}"
    ${recovery_function}
    local recovery_code=$?

    if [ ${recovery_code} -eq 0 ]; then
      print_message "${GREEN}" "Recovery successful"
      log_message "INFO" "Recovery successful"
      return 0
    else
      print_message "${RED}" "Recovery failed (Code: ${recovery_code})"
      log_message "ERROR" "Recovery failed (Code: ${recovery_code})"
      return "${error_code}"
    fi
  else
    print_message "${YELLOW}" "No recovery function available"
    log_message "INFO" "No recovery function available"
    return "${error_code}"
  fi
}

# Function to display troubleshooting information
display_troubleshooting() {
  local error_code="$1"
  local component="$2"

  print_message "${BLUE}" "=== Troubleshooting Information ==="

  case "${component}" in
    "kubernetes")
      print_message "${YELLOW}" "Kubernetes Troubleshooting:"
      print_message "${YELLOW}" "1. Check if Kubernetes is running:"
      print_message "${NC}" "   kubectl cluster-info"
      print_message "${YELLOW}" "2. Check if the namespace exists:"
      print_message "${NC}" "   kubectl get namespace ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "3. Check for any pods in the namespace:"
      print_message "${NC}" "   kubectl get pods -n ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "4. Check for events in the namespace:"
      print_message "${NC}" "   kubectl get events -n ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "5. Fix permissions and try again:"
      print_message "${NC}" "   ${REPO_ROOT}/scripts/fix-permissions.sh"
      ;;

    "terraform")
      print_message "${YELLOW}" "OpenTofu Troubleshooting:"
      print_message "${YELLOW}" "1. Check OpenTofu state:"
      print_message "${NC}" "   cd ${TERRAFORM_DIR} && tofu state list"
      print_message "${YELLOW}" "2. Fix permissions and try again:"
      print_message "${NC}" "   ${REPO_ROOT}/scripts/fix-permissions.sh"
      print_message "${YELLOW}" "3. Reinitialize OpenTofu:"
      print_message "${NC}" "   cd ${TERRAFORM_DIR} && tofu init -reconfigure"
      print_message "${YELLOW}" "4. Run with verbose logging:"
      print_message "${NC}" "   cd ${TERRAFORM_DIR} && TF_LOG=DEBUG tofu apply"
      ;;

    "wazuh")
      print_message "${YELLOW}" "Wazuh Troubleshooting:"
      print_message "${YELLOW}" "1. Check if Wazuh pods are running:"
      print_message "${NC}" "   kubectl get pods -n ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "2. Check pod logs:"
      print_message "${NC}" "   kubectl logs -n ${WAZUH_NAMESPACE} <pod-name>"
      print_message "${YELLOW}" "3. Check pod descriptions:"
      print_message "${NC}" "   kubectl describe pod -n ${WAZUH_NAMESPACE} <pod-name>"
      print_message "${YELLOW}" "4. Check for events in the namespace:"
      print_message "${NC}" "   kubectl get events -n ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "5. Try manual deployment:"
      print_message "${NC}" "   cd ${WAZUH_KUBERNETES_REPO}/envs/local-env && kubectl apply -k ."
      ;;

    *)
      print_message "${YELLOW}" "General Troubleshooting:"
      print_message "${YELLOW}" "1. Check the deployment log:"
      print_message "${NC}" "   cat ${LOG_FILE}"
      print_message "${YELLOW}" "2. Fix permissions and try again:"
      print_message "${NC}" "   ${REPO_ROOT}/scripts/fix-permissions.sh"
      print_message "${YELLOW}" "3. Validate Kubernetes configuration:"
      print_message "${NC}" "   ${REPO_ROOT}/scripts/utils/k8s_validator.sh"
      print_message "${YELLOW}" "4. Check the TROUBLESHOOTING.md file for more information"
      ;;
  esac

  print_message "${BLUE}" "=== End of Troubleshooting Information ==="
}

# Recovery functions

# Function to recover from Kubernetes access issues
recover_kubernetes_access() {
  print_message "${YELLOW}" "Attempting to recover Kubernetes access..."

  # Check if kubeconfig exists
  if [ ! -f "${KUBE_CONFIG_PATH}" ]; then
    print_message "${YELLOW}" "Kubeconfig not found at ${KUBE_CONFIG_PATH}"

    # Try to find kubeconfig in default locations
    local kubeconfig_path
    kubeconfig_path=$(resolve_kubeconfig)

    if [ -n "${kubeconfig_path}" ]; then
      print_message "${GREEN}" "Found kubeconfig at ${kubeconfig_path}"
      update_config "KUBE_CONFIG_PATH" "${kubeconfig_path}"
      KUBE_CONFIG_PATH="${kubeconfig_path}"
    else
      print_message "${RED}" "Could not find kubeconfig"
      return 1
    fi
  fi

  # Fix permissions on kubeconfig
  if [ -f "${KUBE_CONFIG_PATH}" ]; then
    print_message "${YELLOW}" "Fixing permissions on ${KUBE_CONFIG_PATH}"
    chmod 600 "${KUBE_CONFIG_PATH}"
  fi

  # Try to access Kubernetes
  export KUBECONFIG="${KUBE_CONFIG_PATH}"
  if kubectl cluster-info &> /dev/null; then
    print_message "${GREEN}" "Kubernetes access recovered"
    return 0
  else
    print_message "${RED}" "Could not recover Kubernetes access"
    return 1
  fi
}

# Function to recover from OpenTofu state issues
recover_terraform_state() {
  print_message "${YELLOW}" "Attempting to recover OpenTofu state..."

  # Check if terraform directory exists
  if [ ! -d "${TERRAFORM_DIR}" ]; then
    print_message "${RED}" "Terraform directory not found at ${TERRAFORM_DIR}"
    return 1
  fi

  # Fix permissions on terraform directory
  print_message "${YELLOW}" "Fixing permissions on ${TERRAFORM_DIR}"
  chmod -R u+rw "${TERRAFORM_DIR}"

  # Remove lock files
  if [ -f "${TERRAFORM_DIR}/.terraform.lock.hcl" ]; then
    print_message "${YELLOW}" "Removing OpenTofu lock file"
    rm -f "${TERRAFORM_DIR}/.terraform.lock.hcl"
  fi

  if [ -f "${TERRAFORM_DIR}/.terraform/terraform.tfstate.lock.info" ]; then
    print_message "${YELLOW}" "Removing OpenTofu state lock file"
    rm -f "${TERRAFORM_DIR}/.terraform/terraform.tfstate.lock.info"
  fi

  # Reinitialize OpenTofu
  print_message "${YELLOW}" "Reinitializing OpenTofu"
  if cd "${TERRAFORM_DIR}" && tofu init -reconfigure &> /dev/null; then
    print_message "${GREEN}" "OpenTofu state recovered"
    return 0
  else
    print_message "${RED}" "Could not recover OpenTofu state"
    return 1
  fi
}

# Function to recover from Wazuh deployment issues
recover_wazuh_deployment() {
  print_message "${YELLOW}" "Attempting to recover Wazuh deployment..."

  # Check if namespace exists
  export KUBECONFIG="${KUBE_CONFIG_PATH}"
  if ! kubectl get namespace "${WAZUH_NAMESPACE}" &> /dev/null; then
    print_message "${YELLOW}" "Creating namespace ${WAZUH_NAMESPACE}"
    kubectl create namespace "${WAZUH_NAMESPACE}" &> /dev/null
  fi

  # Check if wazuh-kubernetes repository exists
  if [ ! -d "${WAZUH_KUBERNETES_REPO}" ]; then
    print_message "${YELLOW}" "Cloning Wazuh Kubernetes repository"
    git clone --branch "${WAZUH_KUBERNETES_VERSION}" https://github.com/wazuh/wazuh-kubernetes.git "${WAZUH_KUBERNETES_REPO}" &> /dev/null
  fi

  # Try manual deployment
  if [ -d "${WAZUH_KUBERNETES_REPO}/envs/local-env" ]; then
    print_message "${YELLOW}" "Attempting manual deployment from local-env"
    if cd "${WAZUH_KUBERNETES_REPO}/envs/local-env" && kubectl apply -k . &> /dev/null; then
      print_message "${GREEN}" "Wazuh deployment recovered"
      return 0
    fi
  fi

  # Try fallback deployment
  print_message "${YELLOW}" "Attempting fallback deployment"

  # Create secrets
  kubectl -n "${WAZUH_NAMESPACE}" create secret generic wazuh-cluster-key-secret --from-literal=key="$(openssl rand -base64 32)" &> /dev/null
  kubectl -n "${WAZUH_NAMESPACE}" create secret generic wazuh-authd-pass-secret --from-literal=password="$(openssl rand -base64 16)" &> /dev/null
  kubectl -n "${WAZUH_NAMESPACE}" create secret generic wazuh-api-cred-secret --from-literal=username=wazuh-api --from-literal=password="$(openssl rand -base64 16)" &> /dev/null
  kubectl -n "${WAZUH_NAMESPACE}" create secret generic indexer-cred-secret --from-literal=username=admin --from-literal=password="$(openssl rand -base64 16)" &> /dev/null
  kubectl -n "${WAZUH_NAMESPACE}" create secret generic dashboard-cred-secret --from-literal=username=admin --from-literal=password="$(openssl rand -base64 16)" &> /dev/null

  # Deploy components using fallback manifests
  if [ -d "${REPO_ROOT}/fallback-manifests" ]; then
    print_message "${YELLOW}" "Deploying from fallback manifests"
    if kubectl apply -f "${REPO_ROOT}/fallback-manifests" -n "${WAZUH_NAMESPACE}" &> /dev/null; then
      print_message "${GREEN}" "Wazuh deployment recovered using fallback manifests"
      return 0
    fi
  fi

  print_message "${RED}" "Could not recover Wazuh deployment"
  return 1
}

# If script is run directly, display help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  print_message "${GREEN}" "Error Handler Utility"
  print_message "${YELLOW}" "This script is meant to be sourced by other scripts"
  print_message "${YELLOW}" "Example usage:"
  print_message "${NC}" "source ${SCRIPT_DIR}/error_handler.sh"
  print_message "${NC}" "handle_error 1 \"Failed to access Kubernetes\" recover_kubernetes_access"
  print_message "${NC}" "display_troubleshooting 1 \"kubernetes\""
fi
