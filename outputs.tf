output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "server_public_ip" {
  description = "Public IP address for SSH access to the server."
  value       = azurerm_public_ip.server.ip_address
}

output "vm_private_ips" {
  description = "Private IP addresses of the virtual machines."
  value = {
    for name, nic in azurerm_network_interface.vm : name => nic.private_ip_address
  }
}