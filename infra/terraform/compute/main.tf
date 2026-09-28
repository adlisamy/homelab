terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.8"
    }
  }
}

resource "libvirt_domain" "node" {
  count = var.vm_count

  name        = "${var.name}-${format("%02d", count.index + 1)}"
  memory      = var.memory_mb
  memory_unit = "MiB"
  vcpu        = var.vcpu
  type        = "kvm"
  running     = true
  autostart   = true

  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_machine = "q35"
    firmware     = "efi"

    firmware_info = {
      features = [
        { enabled = "no", name = "enrolled-keys" },
        { enabled = "no", name = "secure-boot" },
      ]
    }

    # boot_devices = [{
    #   dev = "hd"
    # }]
  }

  features = {
    acpi = true
  }

  devices = {
    # Disque OS
    disks = [
      {
        # Driver explicite obligatoire pour qcow2 !
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          volume = {
            pool   = var.pool_name
            volume = var.volume_name[count.index]
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      # Disque Cloud-Init (CDROM)
      {
        device = "cdrom"
        driver = {
          name = "qemu"
          type = "raw"
        }
        source = {
          volume = {
            pool   = var.pool_name
            volume = var.volume_cloudinit_name[count.index]
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    # Interface réseau
    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = { network = var.network_name }
        }
      }
    ]

    # Console série (indispensable pour debug)
    serials = [
      {
        type = "pty"
        target = {
          port = 0
          type = "isa-serial"
        }
      }
    ]

    # Support graphique (optionnel, pour virt-manager)
    graphics = [
      {
        spice = {
          autoport = "yes"
        }
      }
    ]
  }
}