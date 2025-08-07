#!/bin/bash
# fix-permissions.sh - Fixes common permission issues

# Exit on error
set -e

# Script directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source path resolver
source "${SCRIPT_DIR}/utils/path_resolver.sh"

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

# Function to check if we're running as root
check_root() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Function to fix OpenTofu directory permissions
fix_terraform_permissions() {
  print_message "${YELLOW}" "Fixing OpenTofu directory permissions..."

  # Get current user and group
  local user_id=$(id -u)
  local group_id=$(id -g)

  if check_root; then
    # Running as root, need to get the sudo user
    if [ -n "${SUDO_USER}" ]; then
      user_id=$(id -u "${SUDO_USER}")
      group_id=$(id -g "${SUDO_USER}")
      print_message "${GREEN}" "Detected sudo user: ${SUDO_USER} (${user_id}:${group_id})"
    else
      print_message "${YELLOW}" "Running as root but SUDO_USER not set, using current user"
    fi
  fi

  # Fix permissions on terraform directory
  if [ -d "${TERRAFORM_DIR}" ]; then
    print_message "${YELLOW}" "Changing ownership of ${TERRAFORM_DIR} to ${user_id}:${group_id}"
    chown -R "${user_id}":"${group_id}" "${TERRAFORM_DIR}"
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

    print_message "${GREEN}" "✓ OpenTofu directory permissions fixed"
  else
    print_message "${RED}" "ERROR: OpenTofu directory not found at ${TERRAFORM_DIR}"
    return 1
  fi

  return 0
}

# Function to fix kubeconfig permissions
fix_kubeconfig_permissions() {
  print_message "${YELLOW}" "Fixing kubeconfig permissions..."

  # Validate kubeconfig path
  validate_kubeconfig

  # Get current user and group
  local user_id=$(id -u)
  local group_id=$(id -g)

  if check_root; then
    # Running as root, need to get the sudo user
    if [ -n "${SUDO_USER}" ]; then
      user_id=$(id -u "${SUDO_USER}")
      group_id=$(id -g "${SUDO_USER}")
    fi
  fi

  # Fix permissions on kubeconfig
  if [ -f "${KUBE_CONFIG_PATH}" ]; then
    print_message "${YELLOW}" "Changing ownership of ${KUBE_CONFIG_PATH} to ${user_id}:${group_id}"
    chown "${user_id}":"${group_id}" "${KUBE_CONFIG_PATH}"
    chmod 600 "${KUBE_CONFIG_PATH}"

    # Create symlink if needed
    if [ "${KUBE_CONFIG_PATH}" != "${KUBE_CONFIG_SYMLINK}" ] && [ ! -f "${KUBE_CONFIG_SYMLINK}" ]; then
      print_message "${YELLOW}" "Creating symlink from ${KUBE_CONFIG_PATH} to ${KUBE_CONFIG_SYMLINK}"
      ln -sf "${KUBE_CONFIG_PATH}" "${KUBE_CONFIG_SYMLINK}"
      chown -h "${user_id}":"${group_id}" "${KUBE_CONFIG_SYMLINK}"
    fi

    print_message "${GREEN}" "✓ Kubeconfig permissions fixed"
  else
    print_message "${RED}" "ERROR: Kubeconfig not found at ${KUBE_CONFIG_PATH}"
    return 1
  fi

  return 0
}

# Function to fix wazuh-kubernetes repository permissions
fix_wazuh_kubernetes_permissions() {
  print_message "${YELLOW}" "Fixing Wazuh Kubernetes repository permissions..."

  # Get current user and group
  local user_id=$(id -u)
  local group_id=$(id -g)

  if check_root; then
    # Running as root, need to get the sudo user
    if [ -n "${SUDO_USER}" ]; then
      user_id=$(id -u "${SUDO_USER}")
      group_id=$(id -g "${SUDO_USER}")
    fi
  fi

  # Fix permissions on wazuh-kubernetes directory
  if [ -d "${WAZUH_KUBERNETES_REPO}" ]; then
    print_message "${YELLOW}" "Changing ownership of ${WAZUH_KUBERNETES_REPO} to ${user_id}:${group_id}"
    chown -R "${user_id}":"${group_id}" "${WAZUH_KUBERNETES_REPO}"
    chmod -R u+rw "${WAZUH_KUBERNETES_REPO}"

    print_message "${GREEN}" "✓ Wazuh Kubernetes repository permissions fixed"
  else
    print_message "${YELLOW}" "Wazuh Kubernetes repository not found at ${WAZUH_KUBERNETES_REPO}, skipping"
  fi

  return 0
}

# Main function
main() {
  print_message "${GREEN}" "=== Wazuh and OpenTofu Local K3S Permission Fixer ==="

  # Check if running as root
  if ! check_root; then
    print_message "${YELLOW}" "Not running as root, some operations may fail"
    print_message "${YELLOW}" "Consider running with sudo if you encounter permission errors"
  fi

  # Fix OpenTofu permissions
  fix_terraform_permissions

  # Fix kubeconfig permissions
  fix_kubeconfig_permissions

  # Fix wazuh-kubernetes permissions
  fix_wazuh_kubernetes_permissions

  print_message "${GREEN}" "=== Permission fixing complete ==="
  print_message "${GREEN}" "You can now run OpenTofu commands without sudo:"
  print_message "${GREEN}" "cd ${TERRAFORM_DIR} && tofu init && tofu plan -out=wazuh.plan && tofu apply wazuh.plan"
}

# Run main function
main