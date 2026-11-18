resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [control_plane]
    server ansible_host=${azurerm_public_ip.server.ip_address}

    [workers]
    node-0 ansible_host=${azurerm_network_interface.vm["node-0"].private_ip_address}
    node-1 ansible_host=${azurerm_network_interface.vm["node-1"].private_ip_address}

    [workers:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=nnadozie@${azurerm_public_ip.server.ip_address}'

    [k8s_cluster:children]
    control_plane
    workers

    [all:vars]
    ansible_user=nnadozie
    ansible_ssh_private_key_file=~/.ssh/id_rsa
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
}