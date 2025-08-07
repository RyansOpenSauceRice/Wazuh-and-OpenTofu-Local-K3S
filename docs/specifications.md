# Wazuh SIEM Deployment Specifications

## Overview
This document outlines the specifications for deploying Wazuh SIEM using OpenTofu (formerly Terraform), Kubernetes, and Helm on a Fedora Atomic hypervisor. The deployment is designed for local environments, not cloud-based deployments.

## Architecture

### Infrastructure Components
- **Hypervisor**: Fedora Atomic
- **Container Orchestration**: Kubernetes (K8s)
- **Package Management**: Helm
- **Infrastructure as Code**: OpenTofu
- **SIEM Solution**: Wazuh

### Deployment Topology
1. **Fedora Atomic Hypervisor**
   - Hosts the Kubernetes cluster
   - Provides container runtime and system resources

2. **Kubernetes Cluster**
   - Control Plane (single node for local deployment)
   - Worker Node(s) (can be scaled as needed)

3. **Wazuh Components** (deployed via Helm)
   - Wazuh Manager
   - Wazuh Indexer (Elasticsearch)
   - Wazuh Dashboard (Kibana)
   - Wazuh Agents (optional, for monitoring the host system)

## Technical Specifications

### OpenTofu Configuration
- **Provider**: `kubernetes` and `helm`
- **Resources**:
  - Kubernetes namespace for Wazuh
  - Persistent volumes for data storage
  - Helm release for Wazuh components

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
2. Configure Helm chart values for Wazuh
3. Apply OpenTofu configuration to deploy Wazuh via Helm

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
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm Documentation](https://helm.sh/docs/)
- [Fedora Atomic Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)