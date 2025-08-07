# Wazuh and OpenTofu with Kustomize

<div align="center">
  <img src="assets/icons/wazuh.svg" alt="Wazuh SIEM" width="100" />
  <img src="assets/icons/opentofu.svg" alt="OpenTofu" width="100" />
  <br/>
  <img src="assets/icons/entry-level.svg" alt="Entry Level" width="200" />
</div>

This repository contains OpenTofu (formerly Terraform) configurations to deploy Wazuh SIEM on a local Kubernetes cluster running on Fedora Atomic hypervisor using Kustomize.

## Prerequisites

- Fedora Atomic hypervisor
- Kubernetes cluster installed and configured
- kubectl configured to access your cluster
- Git installed
- OpenTofu installed

## Repository Structure

```
.
├── docs/
│   └── specifications.md       # Detailed specifications document
├── terraform/
│   ├── main.tf                 # Main OpenTofu configuration
│   ├── variables.tf            # Variables definition
│   └── outputs.tf              # Output definitions
├── wazuh-kubernetes/           # Cloned Wazuh Kubernetes repository (created during setup)
└── README.md                   # This file
```

## Setup Instructions

### 1. Set up Fedora Atomic Hypervisor

Ensure you have Fedora Atomic installed and running on your system.

### 2. Install Kubernetes

If you don't have Kubernetes installed, you can use k3s for a lightweight Kubernetes distribution:

```bash
curl -sfL https://get.k3s.io | sh -
```

### 3. Configure kubectl

Ensure kubectl is configured to access your cluster:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
chmod 600 ~/.kube/config
```

### 4. Install Git

```bash
# For Fedora/RHEL-based systems
sudo dnf install -y git

# For Debian/Ubuntu-based systems
# sudo apt-get update && sudo apt-get install -y git
```

### 5. Install OpenTofu

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
chmod +x install-opentofu.sh
./install-opentofu.sh --install-method standalone
rm install-opentofu.sh
```

## Deployment

### 1. Initialize OpenTofu

```bash
cd terraform
tofu init
```

### 2. Plan the Deployment

```bash
tofu plan -out=wazuh.plan
```

### 3. Apply the Configuration

```bash
tofu apply wazuh.plan
```

The deployment process will:
1. Create a Kubernetes namespace for Wazuh
2. Clone the official Wazuh Kubernetes repository
3. Configure Kustomize files for local deployment
4. Generate certificates for Wazuh components
5. Deploy Wazuh using Kustomize

### 4. Access Wazuh Dashboard

After deployment, follow the instructions in the output to access the Wazuh dashboard:

```bash
tofu output access_instructions
```

This will provide you with:
- Commands to port-forward the Wazuh dashboard service
- URL to access the dashboard
- Credentials for the dashboard
- Instructions for accessing the Wazuh API

## Customization

You can customize the deployment by modifying the following files:

- `terraform/variables.tf`: Adjust variables like resource limits, namespace, etc.
- `terraform/main.tf`: Customize the Kustomize configuration

## Cleanup

To remove the Wazuh deployment:

```bash
cd terraform
tofu destroy
```

## Documentation

For detailed specifications and architecture information, see [specifications.md](docs/specifications.md).

## Development

### Linting

This repository uses automated linting for:
- Markdown files
- OpenTofu (Terraform) files
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
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kustomize Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Fedora Atomic Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
