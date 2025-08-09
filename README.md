# Wazuh and OpenTofu with Kustomize

[![SIEM](https://img.shields.io/badge/SIEM-Wazuh-blue?style=for-the-badge&logo=wazuh)](https://wazuh.com/)
[![IaC](https://img.shields.io/badge/IaC-OpenTofu-844FBA?style=for-the-badge&logo=terraform)](https://opentofu.org/)
[![Orchestration](https://img.shields.io/badge/orchestration-Kubernetes-326CE5?style=for-the-badge&logo=kubernetes)](https://kubernetes.io/)
[![Config](https://img.shields.io/badge/config-Kustomize-3970E4?style=for-the-badge&logo=kubernetes)](https://kustomize.io/)
[![Platform](https://img.shields.io/badge/platform-Fedora%20Atomic-294172?style=for-the-badge&logo=fedora)](https://fedoraproject.org/atomic/)
[![Status](https://img.shields.io/badge/status-development-yellow?style=for-the-badge&logo=github)](https://github.com/RyansOpenSauceRice/Wazuh-and-OpenTofu-Local-K3S)
[![License](https://img.shields.io/badge/license-AGPL--3.0-blue?style=for-the-badge)](https://www.gnu.org/licenses/agpl-3.0.en.html)
[![Docs](https://img.shields.io/badge/docs-green?style=for-the-badge)](https://github.com/RyansOpenSauceRice/Wazuh-and-OpenTofu-Local-K3S/tree/main/docs)

This repository contains OpenTofu configurations to deploy Wazuh SIEM on a local
Kubernetes cluster running on Fedora Atomic hypervisor using Kustomize.

## Prerequisites

- Fedora Atomic hypervisor or compatible Linux distribution
- Kubernetes cluster (K3s recommended for local deployments)
- OpenSSL for certificate generation
- Git for repository cloning
- OpenTofu for infrastructure as code

## Repository Structure

```bash
.
├── docs/
│   └── specifications.md       # Detailed specifications document
├── opentofu/
│   ├── main.tf                 # Main OpenTofu configuration
│   ├── variables.tf            # Variables definition
│   └── outputs.tf              # Output definitions
├── scripts/                    # Utility scripts
├── TROUBLESHOOTING.md          # Troubleshooting guide
├── wazuh-kubernetes/           # Cloned Wazuh Kubernetes repository (created during setup)
└── README.md                   # This file
```

## Quick Start

The easiest way to get started is to use the provided setup script, which will check for and install all required dependencies:

```bash
# Clone this repository
git clone https://github.com/RyansOpenSauceRice/Wazuh-and-OpenTofu-Local-K3S.git
cd Wazuh-and-OpenTofu-Local-K3S

# Make the setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

The setup script will:

1. Check and install required dependencies (kubectl, OpenTofu, Git, OpenSSL)
2. Set up or detect an existing K3s cluster
3. Configure kubectl to access your cluster
4. Clone the Wazuh Kubernetes repository
5. Initialize OpenTofu

After running the setup script, you can deploy Wazuh:

```bash
cd opentofu
sudo tofu plan -out=wazuh.plan
sudo tofu apply wazuh.plan
```

## Manual Setup Instructions

If you prefer to set up everything manually or if the setup script doesn't work for your environment, follow these steps:

### 1. Set up Fedora Atomic Hypervisor

Ensure you have Fedora Atomic or a compatible Linux distribution installed and running on your system.

### 2. Install K3s (Lightweight Kubernetes)

```bash
# Install K3s with proper permissions for the kubeconfig file
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
```

### 3. Configure kubectl

```bash
# Create .kube directory
mkdir -p ~/.kube

# Copy the K3s kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# Set proper ownership and permissions
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config

# Create a symlink for compatibility with the Terraform configuration
sudo mkdir -p /tmp
sudo ln -sf ~/.kube/config /tmp/kubeconfig

# Verify connection
kubectl get nodes
```

### 4. Install OpenSSL

OpenSSL is required for certificate generation:

```bash
# For Fedora/RHEL-based systems
sudo dnf install -y openssl

# For Debian/Ubuntu-based systems
# sudo apt-get update && sudo apt-get install -y openssl

# For Fedora CoreOS/Atomic
# sudo rpm-ostree install openssl
# sudo systemctl reboot  # Reboot may be required
```

### 5. Install Git

```bash
# For Fedora/RHEL-based systems
sudo dnf install -y git

# For Debian/Ubuntu-based systems
# sudo apt-get update && sudo apt-get install -y git

# For Fedora CoreOS/Atomic
# sudo rpm-ostree install git
# sudo systemctl reboot  # Reboot may be required
```

### 6. Install OpenTofu

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
sudo ./install-opentofu.sh --install-method standalone
rm install-opentofu.sh
```

### 7. Clone the Wazuh Kubernetes Repository

```bash
git clone https://github.com/wazuh/wazuh-kubernetes.git
```

## Deployment

### 1. Initialize OpenTofu

```bash
cd opentofu
sudo tofu init
```

### 2. Plan the Deployment

```bash
sudo tofu plan -out=wazuh.plan
```

### 3. Apply the Configuration

```bash
sudo tofu apply wazuh.plan
```

The deployment process will:

1. Create a Kubernetes namespace for Wazuh
2. Configure Kustomize files for local deployment
3. Generate certificates for Wazuh components
4. Deploy Wazuh using Kustomize

### 4. Access Wazuh Dashboard

After deployment, follow the instructions in the output to access the Wazuh dashboard:

```bash
sudo tofu output access_instructions
```

This will provide you with:

- Commands to port-forward the Wazuh dashboard service
- URL to access the dashboard
- Credentials for the dashboard
- Instructions for accessing the Wazuh API

Example port-forwarding command:

```bash
sudo kubectl port-forward -n wazuh svc/wazuh-dashboard 5601:5601
```

Then access the dashboard at: <https://localhost:5601>

## Troubleshooting

If you encounter any issues during setup or deployment, please refer to the [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
guide for common solutions.

### Utility Scripts

This repository includes several utility scripts to help with common tasks and troubleshooting:

#### Fix Permissions Script

If you encounter permission issues with OpenTofu or Kubernetes, run:

```bash
./scripts/fix-permissions.sh
```

This script will:

- Fix permissions on the OpenTofu directory
- Fix permissions on the kubeconfig file
- Fix permissions on the Wazuh Kubernetes repository

#### Kubernetes Validator

To validate your Kubernetes configuration:

```bash
./scripts/utils/k8s_validator.sh
```

This script checks:

- If kubectl is installed
- If the Kubernetes cluster is accessible
- If the necessary resources are available

#### Path Resolver

The path resolver utility helps with finding and validating paths:

```bash
./scripts/utils/path_resolver.sh
```

This script:

- Creates a configuration file if it doesn't exist
- Validates paths to important directories
- Resolves the kubeconfig path

Common issues include:

- Permission denied when accessing K3s configuration (use `./scripts/fix-permissions.sh`)
- OpenSSL not found during certificate generation
- Kubernetes pods failing to start (use `./scripts/utils/k8s_validator.sh`)
- Package manager not found on Fedora Atomic/CoreOS systems

## Customization

You can customize the deployment by modifying the following files:

- `opentofu/variables.tf`: Adjust variables like resource limits, namespace, etc.
- `opentofu/main.tf`: Customize the Kustomize configuration

## Cleanup

To remove the Wazuh deployment:

```bash
cd opentofu
sudo tofu destroy
```

## Documentation

For detailed specifications and architecture information, see [specifications.md](docs/specifications.md).

## Development

### Linting

This repository uses automated linting for:

- Markdown files
- OpenTofu files
- Shell scripts

To fix linting errors locally before committing, run:

```bash
./scripts/fix-lint-errors.sh
```

See [scripts/README.md](scripts/README.md) for more information about utility scripts.

## References

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh Kubernetes Repository](https://github.com/wazuh/wazuh-kubernetes)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kustomize Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Fedora Atomic Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
