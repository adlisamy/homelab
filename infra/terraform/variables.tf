variable "network_name" {
  description = "Name of the libvirt private network for the lab."
  type        = string
  default     = "homelab-net"
}

variable "network_address" {
  description = "CIDR for the private lab network."
  type        = string
  default     = "192.168.56.1"
}

variable "network_netmask" {
  description = "Netmask for the private lab network."
  type        = string
  default     = "255.255.255.0"
}

variable "vm_name" {
  description = "Name of the first VM to provision."
  type        = string
  default     = "k3s-node"
}

variable "vm_memory_mb" {
  description = "Memory size for the VM in megabytes."
  type        = number
  default     = 4096
}

variable "vm_count" {
  description = "Number of VMs to provision."
  type        = number
  default     = 3
}

variable "vm_vcpu" {
  description = "Number of virtual CPUs for the VM."
  type        = number
  default     = 2
}

variable "disk_size_gb" {
  description = "Size of the disk for the VM in gigabytes."
  type        = number
  default     = 20
}

variable "pool_name" {
  description = "Name of the libvirt storage pool to create."
  type        = string
  default     = "homelab-images"
}

variable "pool_path" {
  description = "Filesystem path for the libvirt storage pool."
  type        = string
  default     = "/var/lib/libvirt/images"
}

variable "base_image_path" {
  description = "Path to a base QCOW2 image that the VM will use as its root disk."
  type        = string
  default     = "/home/sam/homelab/Arch-Linux-x86_64-basic.qcow2"
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "~/.ssh/kvm_ed25519.pub"
}