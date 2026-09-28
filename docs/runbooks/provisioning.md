# Provisioning Runbook

`terraform apply` manages the Ansible inventory as a stateful `local_file` resource. The file is tracked in Terraform state: if it is deleted or modified, the next `terraform apply` detects the drift and recreates it.

## Steps

1. cd infra/terraform && terraform apply

2. cd infra/ansible && ansible-playbook -i inventory/lab playbooks/site.yaml

## Notes

- `-01` suffix = k3s server; the rest = agents.
- IPs "pending"? Run `terraform refresh` then `terraform apply`.
- Manual refresh: `ops/scripts/generate_inventory.sh`.
- SSH host-key checking is enabled. Before the first Ansible run, obtain each VM's
  SSH host-key fingerprint through a trusted channel (for example, the VM console)
  and add the verified key to the control host's `~/.ssh/known_hosts`.

## Files

- infra/terraform/inventory.tf
- infra/terraform/root.tf (local provider)
- ops/scripts/generate_inventory.sh
- infra/ansible/inventory/lab/hosts.yaml (generated)
