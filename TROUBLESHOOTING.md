# Troubleshooting Guide

This document provides solutions to common issues encountered when deploying Wazuh SIEM with OpenTofu and K3s.

## Table of Contents

1. [Kubernetes/K3s Issues](#kubernetes-k3s-issues)
2. [OpenTofu Issues](#opentofu-issues)
3. [Certificate Generation Issues](#certificate-generation-issues)
4. [Wazuh Deployment Issues](#wazuh-deployment-issues)
5. [Package Manager Issues](#package-manager-issues)

## Kubernetes K3s Issues

### K3s Service is Not Running

**Symptoms:**

- `kubectl` commands fail with "connection refused" errors
- `systemctl status k3s` shows the service is inactive or failed

**Solutions:**

1. Start the K3s service:

   ```bash
   sudo systemctl start k3s
   ```

2. Check the logs for errors:

   ```bash
   sudo journalctl -u k3s -n 50
   ```

3. If the service fails to start, try reinstalling K3s:

   ```bash
   sudo /usr/local/bin/k3s-uninstall.sh
   curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
   ```

### Permission Denied When Accessing K3s Configuration

**Symptoms:**

- Error message: "Unable to read /etc/rancher/k3s/k3s.yaml, please start server with --write-kubeconfig-mode or  
  --write-kubeconfig-group to modify kube config permissions"
- Error message: "error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml:  
  permission denied"

**Solutions:**

1. Use sudo with kubectl commands:

   ```bash
   sudo kubectl get nodes
   ```

2. Fix permissions for the k3s.yaml file:

   ```bash
   sudo chmod 644 /etc/rancher/k3s/k3s.yaml
   ```

3. Configure K3s to use proper permissions by default:

   ```bash
   sudo mkdir -p /etc/systemd/system/k3s.service.d/
   sudo tee /etc/systemd/system/k3s.service.d/override.conf > /dev/null << EOF
   [Service]
   ExecStart=
   ExecStart=/usr/local/bin/k3s server --write-kubeconfig-mode 644
   EOF
   sudo systemctl daemon-reload
   sudo systemctl restart k3s
   ```

4. Set up your kubeconfig properly:

   ```bash
   mkdir -p ~/.kube
   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   sudo chown $(id -u):$(id -g) ~/.kube/config
   chmod 600 ~/.kube/config
   export KUBECONFIG=~/.kube/config
   ```

## OpenTofu Issues

### "tofu: command not found" Error

**Symptoms:**

- Error message: "tofu: command not found" when trying to run OpenTofu commands

**Solutions:**

1. Verify OpenTofu installation:

   ```bash
   which tofu
   ```

2. If not found, install OpenTofu:

   ```bash
   curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
   chmod +x install-opentofu.sh
   sudo ./install-opentofu.sh --install-method standalone
   rm install-opentofu.sh
   ```

3. Use the full path to the OpenTofu binary:

   ```bash
   sudo /usr/local/bin/tofu init
   ```

### Invalid Kubeconfig Path in OpenTofu

**Symptoms:**

- Error message: "Invalid attribute in provider configuration: 'config_path' refers to an invalid path"

**Solutions:**

1. Update the `variables.tf` file to use the correct kubeconfig path:

   ```bash
   sed -i 's|default     = "/tmp/kubeconfig"|default     = "~/.kube/config"|g' terraform/variables.tf
   ```

2. Create a symlink to ensure compatibility:

   ```bash
   sudo mkdir -p /tmp
   sudo ln -sf ~/.kube/config /tmp/kubeconfig
   ```

3. Reinitialize OpenTofu with the new configuration:

   ```bash
   cd terraform
   sudo tofu init -reconfigure
   ```

## Certificate Generation Issues

### OpenSSL Not Found

**Symptoms:**

- Error messages like "./generate_certs.sh: line 8: openssl: command not found" during certificate generation

**Solutions:**

1. Install OpenSSL using your package manager:

   For Fedora/RHEL-based systems:

   ```bash
   sudo dnf install -y openssl
   ```

   For Debian/Ubuntu-based systems:

   ```bash
   sudo apt-get update && sudo apt-get install -y openssl
   ```

   For Fedora CoreOS/Atomic:

   ```bash
   sudo rpm-ostree install openssl
   sudo systemctl reboot
   ```

2. After installing OpenSSL, rerun the deployment:

   ```bash
   cd terraform
   sudo tofu apply wazuh.plan
   ```

## Wazuh Deployment Issues

### Wazuh Pods Fail to Start

**Symptoms:**

- Pods remain in "Pending" or "CrashLoopBackOff" state
- Error messages in pod logs

**Solutions:**

1. Check pod status and logs:

   ```bash
   sudo kubectl get pods -n wazuh
   sudo kubectl describe pod <pod-name> -n wazuh
   sudo kubectl logs <pod-name> -n wazuh
   ```

2. Verify storage class and persistent volumes:

   ```bash
   sudo kubectl get storageclass
   sudo kubectl get pv
   sudo kubectl get pvc -n wazuh
   ```

3. Check if your cluster has enough resources:

   ```bash
   sudo kubectl describe nodes
   ```

4. If resource constraints are the issue, adjust the resource limits in `variables.tf` and reapply.

## Package Manager Issues

### DNF or YUM Not Found

**Symptoms:**

- Error message: "dnf: command not found" or "yum: command not found"

**Solutions:**

1. For Fedora CoreOS/Atomic, use rpm-ostree instead:

   ```bash
   sudo rpm-ostree install <package-name>
   ```

2. After installing packages with rpm-ostree, you may need to reboot:

   ```bash
   sudo systemctl reboot
   ```

3. For container-based systems, you might need to use the container's package manager or build a custom container with  
   the required packages.

## Still Having Issues?

If you're still experiencing problems after trying these solutions:

1. Check the Wazuh documentation: <https://documentation.wazuh.com/>
2. Check the K3s documentation: <https://docs.k3s.io/>
3. Check the OpenTofu documentation: <https://opentofu.org/docs/>
4. Open an issue in the GitHub repository with detailed information about your problem, including:
   - Error messages
   - System information (OS, kernel version)
   - Steps you've already tried
