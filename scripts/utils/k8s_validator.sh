#!/bin/bash
# k8s_validator.sh - Validates Kubernetes configuration and resources

# Exit on error
set -e

# Script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# REPO_ROOT is used in path_resolver.sh
export REPO_ROOT
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source path resolver
# shellcheck source=./path_resolver.sh disable=SC1091
source "${SCRIPT_DIR}/path_resolver.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color="$1"
  local message="$2"
  echo -e "${color}${message}${NC}"
}

# Function to check if kubectl is installed
check_kubectl() {
  if command -v kubectl &> /dev/null; then
    print_message "${GREEN}" "✓ kubectl is installed"
    return 0
  else
    print_message "${RED}" "ERROR: kubectl is not installed"
    return 1
  fi
}

# Function to check if Kubernetes cluster is accessible
check_cluster_access() {
  print_message "${YELLOW}" "Checking Kubernetes cluster access..."

  # Set KUBECONFIG environment variable
  export KUBECONFIG="${KUBE_CONFIG_PATH}"

  # Try to get cluster info
  if kubectl cluster-info &> /dev/null; then
    print_message "${GREEN}" "✓ Kubernetes cluster is accessible"
    return 0
  else
    print_message "${RED}" "ERROR: Cannot access Kubernetes cluster"
    print_message "${YELLOW}" "Make sure your kubeconfig is correctly set up at ${KUBE_CONFIG_PATH}"
    return 1
  fi
}

# Function to check if namespace exists or can be created
check_namespace() {
  print_message "${YELLOW}" "Checking namespace ${WAZUH_NAMESPACE}..."

  # Set KUBECONFIG environment variable
  export KUBECONFIG="${KUBE_CONFIG_PATH}"

  # Check if namespace exists
  if kubectl get namespace "${WAZUH_NAMESPACE}" &> /dev/null; then
    print_message "${GREEN}" "✓ Namespace ${WAZUH_NAMESPACE} exists"
    return 0
  else
    print_message "${YELLOW}" "Namespace ${WAZUH_NAMESPACE} does not exist, checking if it can be created..."

    # Try to create namespace
    if kubectl create namespace "${WAZUH_NAMESPACE}" &> /dev/null; then
      print_message "${GREEN}" "✓ Namespace ${WAZUH_NAMESPACE} created"
      # Delete the namespace since this is just a check
      kubectl delete namespace "${WAZUH_NAMESPACE}" &> /dev/null
      return 0
    else
      print_message "${RED}" "ERROR: Cannot create namespace ${WAZUH_NAMESPACE}"
      print_message "${YELLOW}" "Make sure you have the necessary permissions"
      return 1
    fi
  fi
}

# Function to check cluster resources
check_cluster_resources() {
  print_message "${YELLOW}" "Checking cluster resources..."

  # Set KUBECONFIG environment variable
  export KUBECONFIG="${KUBE_CONFIG_PATH}"

  # Get nodes
  local nodes
  nodes=$(kubectl get nodes -o name)

  if [ -z "${nodes}" ]; then
    print_message "${RED}" "ERROR: No nodes found in the cluster"
    return 1
  fi

  print_message "${GREEN}" "✓ Found $(echo "${nodes}" | wc -l) node(s) in the cluster"

  # Check CPU and memory resources
  local total_cpu=0
  local total_memory=0
  local node_count=0

  for node in ${nodes}; do
    # Get allocatable CPU and memory
    local cpu
    cpu=$(kubectl get "${node}" -o jsonpath='{.status.allocatable.cpu}')
    local memory
    memory=$(kubectl get "${node}" -o jsonpath='{.status.allocatable.memory}')

    # Convert memory to Mi
    memory=$(echo "${memory}" | sed 's/Ki$//' | awk '{print int($1/1024)}')

    # Add to totals
    total_cpu=$((total_cpu + ${cpu//[^0-9]/}))
    total_memory=$((total_memory + memory))
    node_count=$((node_count + 1))
  done

  print_message "${GREEN}" "✓ Total allocatable resources: ${total_cpu} CPU, ${total_memory}Mi memory"

  # Check if resources are sufficient
  if [ ${total_cpu} -lt 2 ]; then
    print_message "${YELLOW}" "WARNING: Low CPU resources (${total_cpu}), Wazuh may not run optimally"
    print_message "${YELLOW}" "Recommended: At least 2 CPU cores"
  fi

  if [ ${total_memory} -lt 4096 ]; then
    print_message "${YELLOW}" "WARNING: Low memory resources (${total_memory}Mi), Wazuh may not run optimally"
    print_message "${YELLOW}" "Recommended: At least 4096Mi (4Gi) memory"
  fi

  return 0
}

# Function to check storage class
check_storage_class() {
  print_message "${YELLOW}" "Checking storage class ${STORAGE_CLASS}..."

  # Set KUBECONFIG environment variable
  export KUBECONFIG="${KUBE_CONFIG_PATH}"

  # Check if storage class exists
  if kubectl get storageclass "${STORAGE_CLASS}" &> /dev/null; then
    print_message "${GREEN}" "✓ Storage class ${STORAGE_CLASS} exists"
    return 0
  else
    print_message "${YELLOW}" "Storage class ${STORAGE_CLASS} does not exist, it will be created during deployment"
    return 0
  fi
}

# Function to check Kubernetes version
check_kubernetes_version() {
  print_message "${YELLOW}" "Checking Kubernetes version..."

  # Set KUBECONFIG environment variable
  export KUBECONFIG="${KUBE_CONFIG_PATH}"

  # Get Kubernetes version
  local version
  version=$(kubectl version --short 2>/dev/null | grep "Server Version" | awk '{print $3}' | sed 's/v//')

  if [ -z "${version}" ]; then
    print_message "${YELLOW}" "WARNING: Could not determine Kubernetes version"
    return 0
  fi

  print_message "${GREEN}" "✓ Kubernetes version: ${version}"

  # Check if version is sufficient
  local major
  major=$(echo "${version}" | cut -d. -f1)
  local minor
  minor=$(echo "${version}" | cut -d. -f2)

  if [ "${major}" -lt 1 ] || { [ "${major}" -eq 1 ] && [ "${minor}" -lt 19 ]; }; then
    print_message "${YELLOW}" "WARNING: Kubernetes version ${version} may be too old for Wazuh"
    print_message "${YELLOW}" "Recommended: Kubernetes 1.19 or newer"
  fi

  return 0
}

# Main function to validate Kubernetes
validate_kubernetes() {
  print_message "${GREEN}" "=== Kubernetes Validation ==="

  local exit_code=0

  # Check if kubectl is installed
  check_kubectl || exit_code=1

  # If kubectl is not installed, exit early
  if [ ${exit_code} -ne 0 ]; then
    print_message "${RED}" "ERROR: kubectl is required for Kubernetes validation"
    return ${exit_code}
  fi

  # Check if Kubernetes cluster is accessible
  check_cluster_access || exit_code=1

  # If cluster is not accessible, exit early
  if [ ${exit_code} -ne 0 ]; then
    print_message "${RED}" "ERROR: Kubernetes cluster access is required for validation"
    return ${exit_code}
  fi

  # Check if namespace exists or can be created
  check_namespace || exit_code=1

  # Check cluster resources
  check_cluster_resources || exit_code=1

  # Check storage class
  check_storage_class || exit_code=1

  # Check Kubernetes version
  check_kubernetes_version || exit_code=1

  if [ ${exit_code} -eq 0 ]; then
    print_message "${GREEN}" "✓ Kubernetes validation passed"
  else
    print_message "${RED}" "✗ Kubernetes validation failed"
  fi

  return ${exit_code}
}

# If script is run directly, validate Kubernetes
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  validate_kubernetes
fi
