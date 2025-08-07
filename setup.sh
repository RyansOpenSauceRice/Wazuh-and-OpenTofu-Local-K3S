#!/bin/bash

# Setup script for Wazuh SIEM deployment with OpenTofu and Helm on Fedora Atomic

set -e

echo "=== Wazuh SIEM Deployment Setup ==="
echo "This script will help you set up the necessary components for deploying Wazuh SIEM."

# Check if running on Fedora Atomic
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "fedora-coreos" && "$ID" != "fedora" ]]; then
        echo "Warning: This script is designed for Fedora Atomic. You are running $PRETTY_NAME."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
            echo "Exiting."
            exit 1
        fi
    fi
fi

# Check for required tools
echo "Checking for required tools..."

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed."
else
    echo "kubectl is already installed."
fi

# Check for Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Kubernetes cluster not found or not accessible."
    echo "Would you like to install k3s (a lightweight Kubernetes distribution)?"
    read -p "Install k3s? (y/n): " install_k3s
    if [[ "$install_k3s" == "y" || "$install_k3s" == "Y" ]]; then
        echo "Installing k3s..."
        curl -sfL https://get.k3s.io | sh -
        # Wait for k3s to start
        echo "Waiting for k3s to start..."
        sleep 10
        # Configure kubectl
        mkdir -p ~/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        sudo chown $(id -u):$(id -g) ~/.kube/config
        chmod 600 ~/.kube/config
        export KUBECONFIG=~/.kube/config
        echo "k3s installed and kubectl configured."
    else
        echo "Please set up a Kubernetes cluster and configure kubectl before continuing."
        exit 1
    fi
else
    echo "Kubernetes cluster is accessible."
fi

# Check for Helm
if ! command -v helm &> /dev/null; then
    echo "Helm not found. Installing..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed."
else
    echo "Helm is already installed."
fi

# Check for OpenTofu
if ! command -v tofu &> /dev/null; then
    echo "OpenTofu not found. Installing..."
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method standalone
    rm install-opentofu.sh
    echo "OpenTofu installed."
else
    echo "OpenTofu is already installed."
fi

# Add Wazuh Helm repository
echo "Adding Wazuh Helm repository..."
helm repo add wazuh https://wazuh.github.io/helm
helm repo update

# Initialize OpenTofu
echo "Initializing OpenTofu..."
cd terraform
tofu init

echo "Setup complete! You can now deploy Wazuh SIEM using OpenTofu."
echo "To deploy, run the following commands:"
echo "  cd terraform"
echo "  tofu plan -out=wazuh.plan"
echo "  tofu apply wazuh.plan"
echo ""
echo "After deployment, run 'tofu output access_instructions' to get access information."