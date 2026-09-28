variable "name" {
  description = "Name of the VM domain."
  type        = string
}

variable "memory_mb" {
  description = "Memory size for the VM in megabytes."
  type        = number
}

variable "vcpu" {
  description = "Number of virtual CPUs for the VM."
  type        = number
}

variable "network_id" {
  description = "ID of the libvirt network to attach the VM to."
  type        = string
}

variable "network_name" {
  description = "Name of the libvirt network to attach the VM to."
  type        = string
}

variable "pool_name" {
  description = "Name of the libvirt storage pool that contains the root volume."
  type        = string
}

variable "volume_name" {
  description = "Names of the libvirt volumes to attach as root disks (one per VM)."
  type        = list(string)
}

variable "volume_cloudinit_name" {
  description = "Names of the libvirt volumes to attach as cloud-init disks (one per VM)."
  type        = list(string)
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé SSH publique"
  type        = string
  default     = "~/.ssh/kvm_ed25519.pub"
}

variable "vm_count" {
  description = "Number of VMs to provision."
  type        = number
  default     = 1
}