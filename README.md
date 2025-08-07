# Wazuh and OpenTofu with Helm

This repository contains OpenTofu (formerly Terraform) configurations to deploy Wazuh SIEM on a local Kubernetes cluster running on Fedora Atomic hypervisor using Helm charts.

## Prerequisites

- Fedora Atomic hypervisor
- Kubernetes cluster installed and configured
- kubectl configured to access your cluster
- Helm installed
- OpenTofu installed

## Repository Structure

```
.
├── docs/
│   └── specifications.md       # Detailed specifications document
├── helm_charts/
│   └── wazuh-values.yaml       # Helm values for Wazuh deployment
├── terraform/
│   ├── main.tf                 # Main OpenTofu configuration
│   ├── variables.tf            # Variables definition
│   └── outputs.tf              # Output definitions
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

### 4. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
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

### 4. Access Wazuh Dashboard

After deployment, follow the instructions in the output to access the Wazuh dashboard:

```bash
tofu output access_instructions
```

## Customization

You can customize the deployment by modifying the following files:

- `terraform/variables.tf`: Adjust variables like storage size, namespace, etc.
- `helm_charts/wazuh-values.yaml`: Customize Wazuh configuration

## Cleanup

To remove the Wazuh deployment:

```bash
cd terraform
tofu destroy
```

## Documentation

For detailed specifications and architecture information, see [specifications.md](docs/specifications.md).

## References

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm Documentation](https://helm.sh/docs/)
- [Fedora Atomic Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
