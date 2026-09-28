# Architecture Decisions

Record significant design choices here as the environment evolves.

## Suggested format
- Date
- Decision
- Context
- Consequences

## Initial decisions
- Use a 3-node k3s cluster for realistic multi-node behavior
- Keep the host machine separate from the cluster runtime
- Use ingress and cert-manager for TLS termination
- Treat GitOps and observability as core platform services
