output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "jumpbox_public_ip" {
  description = "Public IP address for SSH access to the jumpbox."
  value       = azurerm_public_ip.jumpbox.ip_address
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines."
  value = {
    for name, nic in azurerm_network_interface.vm : name => nic.private_ip_address
  }
}