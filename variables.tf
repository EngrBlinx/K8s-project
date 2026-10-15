variable "resource_group_name" {
  default = "k8s-the-hard-way"
}

variable "admin_username" {
  description = "Administrator username for the Linux virtual machines."
  type        = string
  default     = "nnadozie"
}

variable "admin_ssh_public_key" {
  description = "SSH public key used to access the virtual machines."
  type        = string
}

variable "admin_cidr" {
  description = "IPv4 CIDR allowed to connect to SSH on the virtual network."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.admin_cidr))
    error_message = "admin_cidr must be a valid IPv4 CIDR range."
  }
}