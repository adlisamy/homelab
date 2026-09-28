output "network_id" {
  description = "The ID of the created libvirt network."
  value       = module.networking.network_id
}

output "vm_name" {
  description = "The names of the provisioned VMs."
  value       = module.compute.domain_name
}

# Data source pour récupérer les IPs via DHCP leases (une par VM)
data "libvirt_domain_interface_addresses" "vm" {
  for_each = toset(module.compute.domain_name)

  domain = each.value
  source = "lease" # Utilise le serveur DHCP de libvirt

  depends_on = [module.compute]
}

# Toutes les IPs (format 0.9.x : interfaces[].addrs[].addr)
output "ip_addresses" {
  description = "Adresses IP des VMs"
  value = {
    for name, iface_data in data.libvirt_domain_interface_addresses.vm :
    name => [
      for iface in iface_data.interfaces :
      [for a in iface.addrs : a.addr]
    ]
  }
}

# IPs principales pour faciliter l'usage
output "primary_ip" {
  description = "Adresse IP principale de chaque VM"
  value = {
    for name, iface_data in data.libvirt_domain_interface_addresses.vm :
    name => try(
      iface_data.interfaces[0].addrs[0].addr,
      "Non disponible"
    )
  }
}

output "ssh_command" {
  description = "Commandes SSH pour se connecter à chaque VM"
  value = {
    for name, iface_data in data.libvirt_domain_interface_addresses.vm :
    name => try(
      "ssh ubuntu@${iface_data.interfaces[0].addrs[0].addr}",
      "IP non disponible - attendre cloud-init puis: terraform refresh"
    )
  }
}