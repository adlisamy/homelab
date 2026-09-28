terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
  }
}

resource "libvirt_network" "lab" {
  name      = var.network_name
  autostart = true

  forward = {
    nat = {
      enabled = true
    }
  }

  ips = [{
    address = var.network_address
    netmask = var.network_netmask
    dhcp = {
      ranges = [{
        start = "192.168.56.10"
        end   = "192.168.56.200"
      }]
    }
  }]
}
