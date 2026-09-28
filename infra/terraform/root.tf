terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

module "networking" {
  source = "./networking"

  network_name    = var.network_name
  network_address = var.network_address
  network_netmask = var.network_netmask
}

module "storage" {
  source = "./storage"

  volume_name      = var.vm_name
  vm_name          = var.vm_name
  volume_base_path = var.base_image_path
  capacity         = var.disk_size_gb
  pool_name        = var.pool_name
  pool_path        = var.pool_path
  vm_count         = var.vm_count
}

module "compute" {
  source = "./compute"

  name                  = var.vm_name
  memory_mb             = var.vm_memory_mb
  vcpu                  = var.vm_vcpu
  network_id            = module.networking.network_id
  network_name          = module.networking.network_name
  pool_name             = var.pool_name
  volume_name           = module.storage.volume_name
  volume_cloudinit_name = module.storage.volume_cloudinit_name
  vm_count              = var.vm_count
}