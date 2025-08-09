#!/bin/bash

# Setup script for Wazuh SIEM deployment with OpenTofu and Kustomize
# Officially supports Fedora Atomic, with best-effort support for Fedora, Ubuntu, and RHEL/CentOS/Alma

set -eu

# Color output functions
red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
green="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 2 || :) 2>&-)"
yellow="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 3 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"

status() { echo "${green}>>> $*${plain}" >&2; }
error() { echo "${red}ERROR:${plain} $*" >&2; exit 1; }
warning() { echo "${yellow}WARNING:${plain} $*" >&2; }

# Cleanup function
TEMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

# Default values
AUTO_DEPLOY=false
USE_CUSTOM_CREDS=false
DASHBOARD_USERNAME="admin"
API_USERNAME="wazuh-api"
INDEXER_USERNAME="admin"
DASHBOARD_PASSWORD=""
API_PASSWORD=""
INDEXER_PASSWORD=""

# Help function
show_help() {
    cat << EOF
Wazuh SIEM Deployment Setup Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help                    Show this help message
    -y, --auto-deploy            Automatically deploy after setup (non-interactive)
    --dashboard-user USER        Set dashboard username (default: admin)
    --dashboard-pass PASS        Set dashboard password (min 8 chars)
    --api-user USER              Set API username (default: wazuh-api)
    --api-pass PASS              Set API password (min 8 chars)
    --indexer-user USER          Set indexer username (default: admin)
    --indexer-pass PASS          Set indexer password (min 8 chars)

EXAMPLES:
    # Interactive setup (default)
    $0

    # Auto-deploy with default credentials
    $0 --auto-deploy

    # Set custom credentials via command line
    $0 --dashboard-user myuser --dashboard-pass mypassword123 \\
       --api-user myapi --api-pass myapipass123 \\
       --indexer-user myindexer --indexer-pass myindexerpass123 \\
       --auto-deploy

NOTES:
    - Officially supports Fedora Atomic
    - Best-effort support for Fedora, Ubuntu, and RHEL/CentOS/Alma
    - Passwords must be at least 8 characters long
    - Usernames must contain only letters, numbers, underscores, and hyphens
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--auto-deploy)
            AUTO_DEPLOY=true
            shift
            ;;
        --dashboard-user)
            DASHBOARD_USERNAME="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        --dashboard-pass)
            DASHBOARD_PASSWORD="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        --api-user)
            API_USERNAME="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        --api-pass)
            API_PASSWORD="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        --indexer-user)
            INDEXER_USERNAME="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        --indexer-pass)
            INDEXER_PASSWORD="$2"
            USE_CUSTOM_CREDS=true
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate command-line credentials if provided
if [ "$USE_CUSTOM_CREDS" = true ]; then
    # Validate usernames
    for user_var in DASHBOARD_USERNAME API_USERNAME INDEXER_USERNAME; do
        user_value="${!user_var}"
        if [[ ! "$user_value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            error "Invalid username '$user_value': must contain only letters, numbers, underscores, and hyphens"
        fi
    done
    
    # Validate passwords if provided
    for pass_var in DASHBOARD_PASSWORD API_PASSWORD INDEXER_PASSWORD; do
        pass_value="${!pass_var}"
        if [ -n "$pass_value" ] && [ ${#pass_value} -lt 8 ]; then
            error "Password for $pass_var must be at least 8 characters long"
        fi
    done
fi

status "Wazuh SIEM Deployment Setup"
echo "This script will install and configure all necessary components for deploying Wazuh SIEM."

# Check if tools are available
available() { command -v "$1" >/dev/null 2>&1; }

# Check for required basic tools upfront
require() {
    local MISSING=''
    for TOOL in "$@"; do
        if ! available "$TOOL"; then
            MISSING="$MISSING $TOOL"
        fi
    done
    echo "$MISSING"
}

# Function to prompt for credentials
prompt_credentials() {
    # Skip prompting if credentials were provided via command line
    if [ "$USE_CUSTOM_CREDS" = true ]; then
        echo
        status "Using credentials provided via command line"
        echo "Dashboard: $DASHBOARD_USERNAME"
        echo "API: $API_USERNAME" 
        echo "Indexer: $INDEXER_USERNAME"
        echo
        return
    fi
    
    echo
    status "Credential Configuration"
    echo "You can configure custom credentials for Wazuh components or use auto-generated ones."
    echo
    
    # Prompt for credential preference
    while true; do
        echo -n "Do you want to set custom credentials? [y/N]: "
        read -r CUSTOM_CREDS
        case "${CUSTOM_CREDS:-n}" in
            [Yy]|[Yy][Ee][Ss]) 
                USE_CUSTOM_CREDS=true
                break
                ;;
            [Nn]|[Nn][Oo]|"") 
                USE_CUSTOM_CREDS=false
                status "Using auto-generated secure passwords"
                break
                ;;
            *) 
                echo "Please answer yes or no."
                ;;
        esac
    done
    
    if [ "$USE_CUSTOM_CREDS" = true ]; then
        echo
        status "Setting up custom credentials"
        
        # Dashboard credentials
        echo "=== Wazuh Dashboard Credentials ==="
        while true; do
            echo -n "Dashboard username [admin]: "
            read -r DASHBOARD_USERNAME
            DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-admin}"
            if [[ "$DASHBOARD_USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                break
            else
                echo "Username must contain only letters, numbers, underscores, and hyphens."
            fi
        done
        
        while true; do
            echo -n "Dashboard password (min 8 chars): "
            read -rs DASHBOARD_PASSWORD
            echo
            if [ ${#DASHBOARD_PASSWORD} -ge 8 ]; then
                echo -n "Confirm password: "
                read -rs DASHBOARD_PASSWORD_CONFIRM
                echo
                if [ "$DASHBOARD_PASSWORD" = "$DASHBOARD_PASSWORD_CONFIRM" ]; then
                    break
                else
                    echo "Passwords do not match. Please try again."
                fi
            else
                echo "Password must be at least 8 characters long."
            fi
        done
        
        # API credentials
        echo
        echo "=== Wazuh API Credentials ==="
        while true; do
            echo -n "API username [wazuh-api]: "
            read -r API_USERNAME
            API_USERNAME="${API_USERNAME:-wazuh-api}"
            if [[ "$API_USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                break
            else
                echo "Username must contain only letters, numbers, underscores, and hyphens."
            fi
        done
        
        while true; do
            echo -n "API password (min 8 chars): "
            read -rs API_PASSWORD
            echo
            if [ ${#API_PASSWORD} -ge 8 ]; then
                echo -n "Confirm password: "
                read -rs API_PASSWORD_CONFIRM
                echo
                if [ "$API_PASSWORD" = "$API_PASSWORD_CONFIRM" ]; then
                    break
                else
                    echo "Passwords do not match. Please try again."
                fi
            else
                echo "Password must be at least 8 characters long."
            fi
        done
        
        # Indexer credentials
        echo
        echo "=== Wazuh Indexer Credentials ==="
        while true; do
            echo -n "Indexer username [admin]: "
            read -r INDEXER_USERNAME
            INDEXER_USERNAME="${INDEXER_USERNAME:-admin}"
            if [[ "$INDEXER_USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                break
            else
                echo "Username must contain only letters, numbers, underscores, and hyphens."
            fi
        done
        
        while true; do
            echo -n "Indexer password (min 8 chars): "
            read -rs INDEXER_PASSWORD
            echo
            if [ ${#INDEXER_PASSWORD} -ge 8 ]; then
                echo -n "Confirm password: "
                read -rs INDEXER_PASSWORD_CONFIRM
                echo
                if [ "$INDEXER_PASSWORD" = "$INDEXER_PASSWORD_CONFIRM" ]; then
                    break
                else
                    echo "Passwords do not match. Please try again."
                fi
            else
                echo "Password must be at least 8 characters long."
            fi
        done
        
        echo
        status "Custom credentials configured successfully"
        echo "Dashboard: $DASHBOARD_USERNAME"
        echo "API: $API_USERNAME" 
        echo "Indexer: $INDEXER_USERNAME"
        echo
    else
        # Set default values for auto-generated credentials
        DASHBOARD_USERNAME="admin"
        API_USERNAME="wazuh-api"
        INDEXER_USERNAME="admin"
        DASHBOARD_PASSWORD=""
        API_PASSWORD=""
        INDEXER_PASSWORD=""
    fi
}

# Function to create credential secrets
create_credential_secrets() {
    local namespace="$1"
    
    if [ "$USE_CUSTOM_CREDS" = true ]; then
        status "Creating custom credential secrets"
        
        # Create secrets with custom credentials
        kubectl -n "$namespace" create secret generic wazuh-authd-pass-secret \
            --from-literal=password="$(openssl rand -base64 16)" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic wazuh-api-cred-secret \
            --from-literal=username="$API_USERNAME" \
            --from-literal=password="$API_PASSWORD" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic indexer-cred-secret \
            --from-literal=username="$INDEXER_USERNAME" \
            --from-literal=password="$INDEXER_PASSWORD" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic dashboard-cred-secret \
            --from-literal=username="$DASHBOARD_USERNAME" \
            --from-literal=password="$DASHBOARD_PASSWORD" &> /dev/null || true
    else
        status "Creating auto-generated credential secrets"
        
        # Generate secure random passwords
        DASHBOARD_PASSWORD="$(openssl rand -base64 16)"
        API_PASSWORD="$(openssl rand -base64 16)"
        INDEXER_PASSWORD="$(openssl rand -base64 16)"
        
        # Create secrets with auto-generated credentials
        kubectl -n "$namespace" create secret generic wazuh-authd-pass-secret \
            --from-literal=password="$(openssl rand -base64 16)" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic wazuh-api-cred-secret \
            --from-literal=username="$API_USERNAME" \
            --from-literal=password="$API_PASSWORD" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic indexer-cred-secret \
            --from-literal=username="$INDEXER_USERNAME" \
            --from-literal=password="$INDEXER_PASSWORD" &> /dev/null || true
            
        kubectl -n "$namespace" create secret generic dashboard-cred-secret \
            --from-literal=username="$DASHBOARD_USERNAME" \
            --from-literal=password="$DASHBOARD_PASSWORD" &> /dev/null || true
    fi
}

# Function to save credentials to file
save_credentials() {
    local creds_file="$1"
    
    status "Saving credentials to $creds_file"
    
    cat > "$creds_file" << EOF
# Wazuh SIEM Credentials
# Generated on $(date)

=== Wazuh Dashboard ===
URL: https://localhost:5601
Username: $DASHBOARD_USERNAME
Password: $DASHBOARD_PASSWORD

=== Wazuh API ===
Username: $API_USERNAME
Password: $API_PASSWORD

=== Wazuh Indexer ===
Username: $INDEXER_USERNAME
Password: $INDEXER_PASSWORD

=== Access Instructions ===
1. Port-forward the dashboard service:
   kubectl port-forward -n wazuh svc/wazuh-dashboard 5601:5601

2. Access the dashboard at: https://localhost:5601

3. Use the dashboard credentials above to log in

Note: Keep this file secure and do not commit it to version control.
EOF
    
    chmod 600 "$creds_file"
    echo "Credentials saved to: $creds_file"
}

# Verify we're on Linux
[ "$(uname -s)" = "Linux" ] || error 'This script is intended to run on Linux only.'

# Check architecture (for kubectl download)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) warning "Architecture $ARCH may not be fully supported" ;;
esac

# Check for basic system tools
NEEDS=$(require curl)
if [ -n "$NEEDS" ]; then
    error "The following basic tools are required but missing:$NEEDS"
fi

# Configure credentials
prompt_credentials

# Detect OS and package manager
if [ ! -f "/etc/os-release" ]; then
    error "Cannot detect operating system."
fi

# shellcheck source=/etc/os-release disable=SC1091
. /etc/os-release
status "Detected OS: $PRETTY_NAME (Architecture: $ARCH)"

# Officially supported: Fedora Atomic/CoreOS
# Best effort support: Fedora, Ubuntu, RHEL/CentOS/Alma
PACKAGE_MANAGER=""
OFFICIALLY_SUPPORTED=false

case "$ID" in
    fedora-coreos)
        status "Fedora Atomic/CoreOS detected - OFFICIALLY SUPPORTED"
        PACKAGE_MANAGER="rpm-ostree"
        OFFICIALLY_SUPPORTED=true
        warning "Some packages may require a reboot with rpm-ostree."
        ;;
    fedora)
        if [ "${VARIANT_ID:-}" = "coreos" ] 2>/dev/null; then
            status "Fedora CoreOS detected - OFFICIALLY SUPPORTED"
            PACKAGE_MANAGER="rpm-ostree"
            OFFICIALLY_SUPPORTED=true
        else
            status "Fedora Desktop detected - BEST EFFORT SUPPORT"
            PACKAGE_MANAGER="dnf"
        fi
        ;;
    ubuntu|debian)
        warning "Ubuntu/Debian detected - BEST EFFORT SUPPORT"
        warning "This project is officially designed for Fedora Atomic."
        PACKAGE_MANAGER="apt-get"
        ;;
    centos|rhel|almalinux|rocky)
        warning "RHEL/CentOS/Alma detected - BEST EFFORT SUPPORT"
        warning "This project is officially designed for Fedora Atomic."
        if available dnf; then
            PACKAGE_MANAGER="dnf"
        elif available yum; then
            PACKAGE_MANAGER="yum"
        else
            error "No supported package manager found."
        fi
        ;;
    *)
        error "Unsupported OS: $PRETTY_NAME. This project officially supports Fedora Atomic only."
        ;;
esac

if [ "$OFFICIALLY_SUPPORTED" = false ]; then
    echo ""
    warning "IMPORTANT: This OS is not officially supported."
    warning "Official support is only provided for Fedora Atomic/CoreOS."
    warning "Continuing with best-effort support..."
    echo ""
    read -r -p "Continue anyway? (y/N): " continue_anyway
    case "$continue_anyway" in
        [Yy]*) status "Proceeding with best-effort support..." ;;
        *) error "Installation cancelled. Please use Fedora Atomic for official support." ;;
    esac
fi

status "Using package manager: $PACKAGE_MANAGER"

# Enhanced package installation function
install_package() {
    local package_name="$1"
    status "Installing $package_name..."

    case "$PACKAGE_MANAGER" in
        apt-get)
            sudo apt-get update -qq && sudo apt-get install -y "$package_name"
            ;;
        dnf)
            sudo dnf install -y "$package_name"
            ;;
        yum)
            sudo yum install -y "$package_name"
            ;;
        rpm-ostree)
            sudo rpm-ostree install "$package_name"
            warning "You may need to reboot for rpm-ostree changes to take effect."
            ;;
        *)
            error "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
}

# Check for required tools
echo "Checking for required tools..."

# Check for OpenSSL (required for certificate generation)
if ! command -v openssl &> /dev/null; then
    echo "OpenSSL not found. This is required for certificate generation."
    install_package "openssl"

    # Verify installation
    if ! command -v openssl &> /dev/null; then
        echo "ERROR: Failed to install OpenSSL. Please install it manually and run this script again."
        exit 1
    fi
else
    echo "OpenSSL is already installed."
fi

# Check for kubectl
if ! available kubectl; then
    status "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    available kubectl || error "Failed to install kubectl"
    status "kubectl installed successfully"
else
    status "kubectl already installed"
fi

# Check for Kubernetes cluster and handle k3s specifically
K3S_RUNNING=false
if systemctl is-active --quiet k3s; then
    echo "K3s service is running."
    K3S_RUNNING=true
else
    if systemctl list-unit-files | grep -q k3s.service; then
        echo "K3s service exists but is not running. Attempting to start..."
        sudo systemctl start k3s
        sleep 10
        if systemctl is-active --quiet k3s; then
            echo "K3s service started successfully."
            K3S_RUNNING=true
        else
            echo "Failed to start K3s service."
        fi
    fi
fi

# Check if kubectl can access the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Kubernetes cluster not found or not accessible."

    # If k3s is running but kubectl can't access it, it's likely a permission issue
    if [ "$K3S_RUNNING" = true ]; then
        echo "K3s is running but kubectl cannot access it. This is likely a permission issue."
        echo "Fixing permissions for k3s.yaml..."

        # Fix permissions for k3s.yaml
        sudo chmod 644 /etc/rancher/k3s/k3s.yaml

        # Configure kubectl to use k3s.yaml
        mkdir -p ~/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        sudo chown "$(id -u)":"$(id -g)" ~/.kube/config
        chmod 600 ~/.kube/config
        export KUBECONFIG=~/.kube/config

        # Create a symlink to /tmp/kubeconfig for compatibility with the Terraform config
        sudo mkdir -p /tmp
        sudo ln -sf ~/.kube/config /tmp/kubeconfig

        echo "kubectl configured to use k3s. Testing connection..."
        if kubectl cluster-info &> /dev/null; then
            echo "Successfully connected to Kubernetes cluster."
        else
            echo "Still unable to connect to Kubernetes cluster."
            echo "Would you like to restart k3s with proper permissions?"
            read -r -p "Restart k3s with proper permissions? (y/n): " restart_k3s
            if [[ "$restart_k3s" == "y" || "$restart_k3s" == "Y" ]]; then
                echo "Configuring k3s to use proper permissions..."
                sudo mkdir -p /etc/systemd/system/k3s.service.d/
                sudo tee /etc/systemd/system/k3s.service.d/override.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s server --write-kubeconfig-mode 644
EOF
                sudo systemctl daemon-reload
                sudo systemctl restart k3s
                sleep 10

                # Try again with the new permissions
                if kubectl cluster-info &> /dev/null; then
                    echo "Successfully connected to Kubernetes cluster after restart."
                else
                    echo "Still unable to connect to Kubernetes cluster. Please check your k3s installation."
                    exit 1
                fi
            else
                echo "Please fix your Kubernetes configuration manually before continuing."
                exit 1
            fi
        fi
    else
        # If k3s is not running, offer to install it
        echo "Would you like to install k3s (a lightweight Kubernetes distribution)?"
        read -r -p "Install k3s? (y/n): " install_k3s
        if [[ "$install_k3s" == "y" || "$install_k3s" == "Y" ]]; then
            echo "Installing k3s with proper permissions..."
            curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

            # Wait for k3s to start
            echo "Waiting for k3s to start..."
            sleep 15

            # Configure kubectl
            mkdir -p ~/.kube
            sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
            sudo chown "$(id -u)":"$(id -g)" ~/.kube/config
            chmod 600 ~/.kube/config
            export KUBECONFIG=~/.kube/config

            # Create a symlink to /tmp/kubeconfig for compatibility with the Terraform config
            sudo mkdir -p /tmp
            sudo ln -sf ~/.kube/config /tmp/kubeconfig

            echo "k3s installed and kubectl configured."

            # Verify connection
            if kubectl cluster-info &> /dev/null; then
                echo "Successfully connected to Kubernetes cluster."
            else
                echo "Unable to connect to Kubernetes cluster after installation. Please check your k3s installation."
                exit 1
            fi
        else
            echo "Please set up a Kubernetes cluster and configure kubectl before continuing."
            exit 1
        fi
    fi
else
    echo "Kubernetes cluster is accessible."

    # Create a symlink to /tmp/kubeconfig for compatibility with the Terraform config
    echo "Creating symlink to kubeconfig for Terraform compatibility..."
    sudo mkdir -p /tmp
    sudo ln -sf ~/.kube/config /tmp/kubeconfig
fi

# Check for kustomize
if ! kubectl kustomize --help &> /dev/null; then
    echo "Kustomize not found in kubectl. Checking standalone installation..."
    if ! command -v kustomize &> /dev/null; then
        echo "Standalone kustomize not found. Installing..."
        curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
        sudo mv kustomize /usr/local/bin/
        echo "Kustomize installed."
    else
        echo "Standalone kustomize is already installed."
    fi
else
    echo "Kustomize is available through kubectl."
fi

# Check for OpenTofu
if ! command -v tofu &> /dev/null; then
    echo "OpenTofu not found. Installing..."
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
    chmod +x install-opentofu.sh
    sudo ./install-opentofu.sh --install-method standalone
    rm install-opentofu.sh

    # Verify installation
    if ! command -v tofu &> /dev/null; then
        echo "ERROR: Failed to install OpenTofu. Please install it manually and run this script again."
        exit 1
    else
        echo "OpenTofu installed successfully."
    fi
else
    echo "OpenTofu is already installed."
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    install_package "git"

    # Verify installation
    if ! command -v git &> /dev/null; then
        echo "ERROR: Failed to install Git. Please install it manually and run this script again."
        exit 1
    else
        echo "Git installed successfully."
    fi
else
    echo "Git is already installed."
fi

# Clone Wazuh Kubernetes repository
echo "Cloning Wazuh Kubernetes repository..."
if [ ! -d "../wazuh-kubernetes" ]; then
    git clone https://github.com/wazuh/wazuh-kubernetes.git ../wazuh-kubernetes
else
    echo "Wazuh Kubernetes repository already exists. Updating..."
    cd ../wazuh-kubernetes && git pull && cd -
fi

# Update Terraform variables to use the correct kubeconfig path
echo "Updating Terraform configuration to use the correct kubeconfig path..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="$SCRIPT_DIR/terraform/variables.tf"

if [ -f "$VARIABLES_FILE" ]; then
    # Backup the original file
    cp "$VARIABLES_FILE" "$VARIABLES_FILE.bak"

    # Update the kubeconfig path
    if grep -q "kube_config_path" "$VARIABLES_FILE"; then
        sed -i 's|default     = "/tmp/kubeconfig"|default     = "~/.kube/config"|g' "$VARIABLES_FILE"
        echo "Updated kubeconfig path in variables.tf"
    else
        echo "WARNING: Could not find kube_config_path in variables.tf"
    fi
else
    echo "WARNING: Could not find variables.tf file at $VARIABLES_FILE"
fi

# Initialize OpenTofu
echo "Initializing OpenTofu..."
cd terraform
tofu init

echo
status "Setup complete! All dependencies are installed."

# Determine if we should deploy
if [ "$AUTO_DEPLOY" = true ]; then
    SHOULD_DEPLOY=true
    status "Auto-deploy enabled, proceeding with deployment..."
else
    # Ask if user wants to deploy now
    echo
    while true; do
        echo -n "Do you want to deploy Wazuh SIEM now? [y/N]: "
        read -r DEPLOY_NOW
        case "${DEPLOY_NOW:-n}" in
            [Yy]|[Yy][Ee][Ss]) 
                SHOULD_DEPLOY=true
                break
                ;;
            [Nn]|[Nn][Oo]|"") 
                SHOULD_DEPLOY=false
                break
                ;;
            *) 
                echo "Please answer yes or no."
                ;;
        esac
    done
fi

if [ "$SHOULD_DEPLOY" = true ]; then
    echo
    status "Deploying Wazuh SIEM..."
    
    # Create namespace if it doesn't exist
    WAZUH_NAMESPACE="wazuh"
    kubectl create namespace "$WAZUH_NAMESPACE" &> /dev/null || true
    
    # Create credential secrets
    create_credential_secrets "$WAZUH_NAMESPACE"
    
    # Run OpenTofu deployment
    status "Running OpenTofu plan..."
    if tofu plan -out=wazuh.plan; then
        status "Applying OpenTofu configuration..."
        if tofu apply wazuh.plan; then
            status "Deployment successful!"
            
            # Save credentials to file
            CREDS_FILE="$(pwd)/wazuh-credentials.txt"
            save_credentials "$CREDS_FILE"
            
            echo
            status "Deployment Complete!"
            echo "Dashboard URL: https://localhost:5601"
            echo "Credentials saved to: $CREDS_FILE"
            echo
            echo "To access the dashboard:"
            echo "1. Port-forward the service: kubectl port-forward -n wazuh svc/wazuh-dashboard 5601:5601"
            echo "2. Open https://localhost:5601 in your browser"
            echo "3. Use the credentials from $CREDS_FILE"
            
        else
            error "OpenTofu apply failed. Check the output above for details."
        fi
    else
        error "OpenTofu plan failed. Check the output above for details."
    fi
else
    echo
    status "Manual Deployment Instructions"
    echo "To deploy Wazuh SIEM manually, run the following commands:"
    echo "  cd terraform"
    echo "  tofu plan -out=wazuh.plan"
    echo "  tofu apply wazuh.plan"
    echo ""
    echo "After deployment, run 'tofu output access_instructions' to get access information."
    echo ""
    echo "Note: If you chose custom credentials, you'll need to create the secrets manually:"
    if [ "$USE_CUSTOM_CREDS" = true ]; then
        echo "  kubectl create namespace wazuh"
        echo "  kubectl -n wazuh create secret generic dashboard-cred-secret --from-literal=username='$DASHBOARD_USERNAME' --from-literal=password='[your-password]'"
        echo "  kubectl -n wazuh create secret generic wazuh-api-cred-secret --from-literal=username='$API_USERNAME' --from-literal=password='[your-password]'"
        echo "  kubectl -n wazuh create secret generic indexer-cred-secret --from-literal=username='$INDEXER_USERNAME' --from-literal=password='[your-password]'"
    fi
fi

echo ""
echo "TROUBLESHOOTING:"
echo "  If you encounter permission issues with kubectl, try using 'sudo kubectl' commands."
echo "  If you encounter 'command not found' errors with tofu, try using the full path: '/usr/local/bin/tofu'"
echo "  For more troubleshooting information, see the TROUBLESHOOTING.md file."
