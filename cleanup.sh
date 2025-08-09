#!/bin/bash

# Cleanup script for Wazuh SIEM deployment
# This script removes existing Wazuh resources to allow for a fresh deployment

set -e

echo "=== Wazuh SIEM Cleanup ==="
echo "This script will remove existing Wazuh resources from your Kubernetes cluster."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl not found. Please ensure kubectl is installed and configured."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot access Kubernetes cluster. Please check your kubectl configuration."
    exit 1
fi

echo "Checking for existing Wazuh resources..."

# Check if wazuh namespace exists
if kubectl get namespace wazuh &> /dev/null; then
    echo "Found existing 'wazuh' namespace."
    read -r -p "Do you want to delete the existing 'wazuh' namespace and all its resources? (y/n): " delete_namespace
    if [[ "$delete_namespace" == "y" || "$delete_namespace" == "Y" ]]; then
        echo "Deleting wazuh namespace..."
        kubectl delete namespace wazuh --timeout=300s
        echo "Wazuh namespace deleted."
    else
        echo "Keeping existing namespace. You may encounter conflicts during deployment."
    fi
else
    echo "No existing 'wazuh' namespace found."
fi

# Check if storage class exists
if kubectl get storageclass wazuh-local-storage &> /dev/null; then
    echo "Found existing 'wazuh-local-storage' storage class."
    read -r -p "Do you want to delete the existing storage class? (y/n): " delete_storage
    if [[ "$delete_storage" == "y" || "$delete_storage" == "Y" ]]; then
        echo "Deleting wazuh-local-storage storage class..."
        kubectl delete storageclass wazuh-local-storage
        echo "Storage class deleted."
    else
        echo "Keeping existing storage class. You may encounter conflicts during deployment."
    fi
else
    echo "No existing 'wazuh-local-storage' storage class found."
fi

# Clean up any terraform state if it exists
if [ -f "terraform/terraform.tfstate" ]; then
    echo "Found existing Terraform state file."
    read -r -p "Do you want to remove the Terraform state file? (y/n): " delete_state
    if [[ "$delete_state" == "y" || "$delete_state" == "Y" ]]; then
        echo "Removing Terraform state..."
        rm -f terraform/terraform.tfstate*
        rm -f terraform/.terraform.lock.hcl
        rm -rf terraform/.terraform/
        echo "Terraform state cleaned up."
    fi
fi

echo "Cleanup complete! You can now run the deployment again."
echo "To deploy Wazuh, run:"
echo "  cd terraform"
echo "  tofu init"
echo "  tofu plan -out=wazuh.plan"
echo "  tofu apply wazuh.plan"