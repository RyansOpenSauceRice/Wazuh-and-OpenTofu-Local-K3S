# Wazuh SIEM Deployment Specifications

[![SIEM: Wazuh](https://img.shields.io/badge/SIEM-Wazuh-blue.svg)](https://wazuh.com/)
[![IaC: OpenTofu](https://img.shields.io/badge/IaC-OpenTofu-844FBA.svg)](https://opentofu.org/)
[![Orchestration: Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5.svg)](https://kubernetes.io/)
[![Config: Helm](https://img.shields.io/badge/Config-Helm-0F1689.svg)](https://helm.sh/)
[![Status: Development](https://img.shields.io/badge/Status-Development-yellow.svg)](https://github.com/RyansOpenSauceRice/Wazuh-and-OpenTofu-with-Helm)
[![Level: Entry](https://img.shields.io/badge/Level-Entry-green.svg)](https://github.com/RyansOpenSauceRice/Wazuh-and-OpenTofu-with-Helm)

## Overview
This document outlines the specifications for deploying Wazuh SIEM using OpenTofu (formerly Terraform) and Kubernetes on a Fedora Atomic hypervisor. The deployment is designed for local environments, not cloud-based deployments.

> **Note**: While the original plan was to use Helm charts for deployment, research shows that the official Wazuh Kubernetes deployment uses Kustomize rather than Helm. This specification has been updated to reflect the official deployment method.

## Architecture

### Infrastructure Components
- **Hypervisor**: Fedora Atomic
- **Container Orchestration**: Kubernetes (K8s)
- **Configuration Management**: Kustomize
- **Infrastructure as Code**: OpenTofu
- **SIEM Solution**: Wazuh

### Deployment Topology
1. **Fedora Atomic Hypervisor**
   - Hosts the Kubernetes cluster
   - Provides container runtime and system resources

2. **Kubernetes Cluster**
   - Control Plane (single node for local deployment)
   - Worker Node(s) (can be scaled as needed)

3. **Wazuh Components** (deployed via Kustomize)
   - Wazuh Manager (Master and Workers)
   - Wazuh Indexer (OpenSearch)
   - Wazuh Dashboard (OpenSearch Dashboards)
   - Wazuh Agents (optional, for monitoring the host system)

## Technical Specifications

### OpenTofu Configuration
- **Provider**: `kubernetes` and `kubectl`
- **Resources**:
  - Kubernetes namespace for Wazuh
  - Persistent volumes for data storage
  - Kustomize deployment for Wazuh components

### Kubernetes Requirements
- Kubernetes version: 1.24+ (recommended)
- Container Runtime: containerd
- CNI Plugin: Calico (recommended)
- Storage Class: Local storage for persistent volumes

### Wazuh Configuration
- **Version**: Latest stable (currently 4.7.x)
- **Components**:
  - Wazuh Manager: Central component for log analysis and security monitoring
  - Wazuh Indexer: For storing and indexing security data
  - Wazuh Dashboard: Web interface for visualization and management

### Resource Requirements
- **Minimum System Requirements**:
  - CPU: 4 cores
  - RAM: 8GB
  - Storage: 50GB (SSD recommended)
- **Recommended System Requirements**:
  - CPU: 8 cores
  - RAM: 16GB
  - Storage: 100GB SSD

## Implementation Plan

### Phase 1: Infrastructure Setup
1. Configure Fedora Atomic hypervisor
2. Install and configure Kubernetes cluster
3. Set up OpenTofu and required providers

### Phase 2: Wazuh Deployment
1. Create OpenTofu configuration for Kubernetes resources
2. Configure Kustomize files for Wazuh deployment
3. Apply OpenTofu configuration to deploy Wazuh via Kustomize

### Phase 3: Configuration and Validation
1. Configure Wazuh for local environment monitoring
2. Validate security monitoring capabilities
3. Set up alerts and notifications

## Maintenance and Operations
- Regular updates of Wazuh components
- Backup strategy for Wazuh data
- Monitoring of Kubernetes cluster health
- Security hardening of the deployment

## Security Considerations
- Network segmentation
- Access control for Wazuh Dashboard
- Encryption of data at rest and in transit
- Regular security updates

## References
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Wazuh Kubernetes Repository](https://github.com/wazuh/wazuh-kubernetes)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kustomize Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Fedora Atomic Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)