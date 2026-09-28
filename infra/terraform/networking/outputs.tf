output "network_id" {
  description = "The ID of the created libvirt network."
  value       = libvirt_network.lab.id
}

output "network_name" {
  description = "The name of the created libvirt network."
  value       = libvirt_network.lab.name
}