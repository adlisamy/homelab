# Architecture Overview

## Target environment
- Host: Ubuntu 24.04 LTS laptop
- Cluster: small multi-node k3s environment running inside VMs
- Goal: practice a realistic platform layout without overcommitting the workstation

## Proposed topology
- 1 control-plane node
- 2 worker nodes
- Dedicated lab network for cluster traffic
- Ingress and TLS handled inside the cluster

## Separation of concerns
- Host: virtualization, DNS, local registry, support tooling
- Cluster: core platform services, workloads, ingress, GitOps, observability

## Expected platform layers
1. Infrastructure layer
2. Platform layer
3. Application layer
4. Operations layer

## Tooling role in the design
- Terraform: provision VMs, networking, and supporting infrastructure resources
- Ansible: configure the nodes, install prerequisites, and prepare the cluster hosts
- k3s: bootstrap and operate the Kubernetes control plane and worker nodes
- GitOps and manifests: deploy platform services and application workloads after the cluster is ready
