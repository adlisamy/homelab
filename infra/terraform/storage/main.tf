terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
  }
}

resource "libvirt_pool" "images" {
  name = var.pool_name
  type = "dir"

  target = {
    path = var.pool_path
  }
}

# Base image — downloaded ONCE and shared as the backing store for all VMs
resource "libvirt_volume" "base" {
  name = var.volume_name
  pool = libvirt_pool.images.name

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }

  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = var.capacity * 1024 * 1024 * 1024
}

# One writable OS volume per VM (copy-on-write over the shared base image)
resource "libvirt_volume" "os" {
  count = var.vm_count

  name     = "${var.vm_name}-${format("%02d", count.index + 1)}.qcow2"
  pool     = libvirt_pool.images.name
  capacity = var.capacity * 1024 * 1024 * 1024 # Conversion en bytes

  target = {
    format = { type = "qcow2" }
  }

  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
}

# One cloud-init ISO per VM (unique hostname + instance-id)
resource "libvirt_cloudinit_disk" "init" {
  count = var.vm_count

  name = "${var.vm_name}-${format("%02d", count.index + 1)}-cloudinit"

  user_data = templatefile("${path.module}/../cloudinit/user-data.yaml", {
    hostname   = "${var.vm_name}-${format("%02d", count.index + 1)}"
    public_key = file(pathexpand(var.ssh_public_key_path))
  })

  # meta_data est OBLIGATOIRE en 0.9.x
  meta_data = yamlencode({
    instance-id    = "${var.vm_name}-${format("%02d", count.index + 1)}"
    local-hostname = "${var.vm_name}-${format("%02d", count.index + 1)}"
  })

  network_config = file("${path.module}/../cloudinit/network-config.yaml")
}

# Upload each cloud-init ISO into the pool so domains can attach it
resource "libvirt_volume" "cloudinit" {
  count = var.vm_count

  name = "${var.vm_name}-${format("%02d", count.index + 1)}-cloudinit.iso"
  pool = libvirt_pool.images.name

  create = {
    content = {
      url = libvirt_cloudinit_disk.init[count.index].path
    }
  }
}