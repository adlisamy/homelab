variable "network_name" {
  description = "Name of the libvirt private network."
  type        = string
}

variable "network_address" {
  description = "IP address for the private network."
  type        = string
}

variable "network_netmask" {
  description = "Netmask for the private network."
  type        = string
}