variable "volume_name" {
  description = "Name of the base disk volume to create."
  type        = string
}

variable "volume_base_path" {
  description = "Path to the source base image to copy into a libvirt volume."
  type        = string
}

variable "capacity" {
  description = "Capacity of the libvirt volume to create."
  type        = number
}

variable "pool_name" {
  description = "Name of the libvirt storage pool to create."
  type        = string
}

variable "pool_path" {
  description = "Filesystem path for the libvirt storage pool."
  type        = string
}

variable "vm_name" {
  description = "Name of the first VM to provision."
  type        = string
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