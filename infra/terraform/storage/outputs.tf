output "pool_name" {
  description = "The name of the libvirt storage pool."
  value       = libvirt_pool.images.name
}

output "volume_id" {
  description = "The IDs of the created OS libvirt volumes (one per VM)."
  value       = libvirt_volume.os[*].id
}

output "volume_name" {
  description = "The names of the created OS libvirt volumes (one per VM)."
  value       = libvirt_volume.os[*].name
}

output "volume_cloudinit_name" {
  description = "The names of the created cloud-init libvirt volumes (one per VM)."
  value       = libvirt_volume.cloudinit[*].name
}