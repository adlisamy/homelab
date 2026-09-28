# Homelab Design

This repository is a conceptual starter layout for a production-like homelab built around a small multi-node k3s cluster.

## Scope
- Provisioning and bootstrap of infrastructure
- Platform services inside the cluster
- Example applications and gateways
- Operational runbooks and documentation

## Recommended implementation flow
1. Terraform provisions the VM-based infrastructure and supporting network resources.
2. Ansible configures the nodes and prepares them for k3s.
3. k3s bootstrap installs and manages the cluster runtime.
4. Platform services and applications are then deployed through GitOps and manifests.

## Top-level structure
- infra/: Terraform, Ansible, and k3s bootstrap assets
- platform/: shared cluster services such as ingress, storage, observability, GitOps, and RBAC
- apps/: application workloads and demo services
- ops/: operational scripts, backups, and incident response guidance
- docs/: architecture notes, diagrams, and design decisions

## Design intent
- Keep the host machine separate from the cluster runtime
- Use a small 3-node k3s layout for realistic multi-node behavior
- Treat ingress, TLS, GitOps, and observability as platform concerns
- Keep documentation and operational procedures explicit from the start
