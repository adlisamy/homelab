output "domain_name" {
  description = "The names of the libvirt domains (one per VM)."
  value       = libvirt_domain.node[*].name
}