locals {
  ssh_user = "ubuntu"
  ssh_key  = "~/.ssh/kvm_ed25519"
  vm_ips = {
    for name, iface in data.libvirt_domain_interface_addresses.vm :
    name => try(iface.interfaces[0].addrs[0].addr, "pending")
  }
  k3s_servers = [for n in sort(keys(local.vm_ips)) : n if endswith(n, "-01")]
  k3s_agents  = [for n in sort(keys(local.vm_ips)) : n if !endswith(n, "-01")]
}

resource "local_file" "ansible_inventory" {
  filename = abspath("${path.module}/../ansible/inventory/lab/hosts.yaml")
  content = templatefile("${path.module}/inventory.tpl", {
    servers  = local.k3s_servers
    agents   = local.k3s_agents
    hosts    = local.vm_ips
    ssh_user = local.ssh_user
    ssh_key  = local.ssh_key
  })
  file_permission = "0644"
}

resource "local_file" "ansible_host_vars" {
  for_each = toset(module.compute.domain_name)

  filename = abspath("${path.module}/../ansible/inventory/lab/host_vars/${each.value}.yaml")
  content = templatefile("${path.module}/host_vars.tpl", {
    hostname = each.value
  })
  file_permission = "0644"
}