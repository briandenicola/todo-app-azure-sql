terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm        = "~> 2.96"
  }
}

provider "azurerm" {
  features  {}
}

data "azurerm_client_config" "current" {}

locals {
    location            = "southcentralus"
    resource_group_name = "MSI_Todo_Testing_RG"
}

resource "azurerm_resource_group" "this" {
  name                  = local.resource_group_name
  location              = local.location
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "my-demo-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_virtual_network" "this" {
  name                = "demo-identity-network"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "servers"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.5.2.0/24"]
}

resource "azurerm_network_interface" "this" {
  name                = "myvm001-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "myvm001"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  size                = "Standard_B2ms"
  admin_username      = "manager"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "manager"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "myvm001-osdisk" 
  }

  identity {
    type = "UserAssigned"
    identity_ids = [ 
        azurerm_user_assigned_identity.this.id
    ]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_mssql_server" "this" {
  name                         = "mysqlserver001"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "manager"
  administrator_login_password = "........................"
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

}

resource "azurerm_sql_database" "this" {
  name                = "todo"
  resource_group_name = azurerm_resource_group.this.name
  location            = local.location
  server_name         = azurerm_mssql_server.this.name
}