#Specify the provider to use
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = " ~> 3.0.2"
    }
  }
  required_version = ">= 1.1.0"
}

#Configure the specified provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "westus2"

  tags = {
    Environment = "Personal project"
    Team        = "DevOps"
  }
}

locals {
  virtual_machines = {
    jumpbox = {
      description = "Administration host"
      size        = "Standard_B1ls"
    }
    server = {
      description = "Kubernetes server"
      size        = "Standard_B1ms"
    }
    node-0 = {
      description = "Kubernetes worker node"
      size        = "Standard_B1ms"
    }
    node-1 = {
      description = "Kubernetes worker node"
      size        = "Standard_B1ms"
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_group_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.resource_group_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vms" {
  name                = "${var.resource_group_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSHFromAdmin"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "vms" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.vms.id
}

resource "azurerm_public_ip" "jumpbox" {
  name                = "jumpbox-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "vm" {
  for_each            = local.virtual_machines
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.key == "jumpbox" ? azurerm_public_ip.jumpbox.id : null
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = local.virtual_machines
  name                            = each.key
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = each.value.size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm[each.key].id]
  depends_on                      = [azurerm_subnet_network_security_group_association.vms]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "${each.key}-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Name        = each.key
    Description = each.value.description
  }
}