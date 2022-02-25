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

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

resource "random_id" "this" {
  byte_length = 2
}

resource "random_pet" "this" {
  length = 1
  separator  = ""
}

resource "random_password" "password" {
  length = 25
  special = true
}

locals {
    location                    = "southcentralus"
    certificate_base64_encoded  = filebase64("${path.module}/${var.certificate_name}")
    resource_name               = "${random_pet.this.id}-${random_id.this.dec}"
}

resource "azurerm_resource_group" "this" {
  name                  = "${local.resource_name}_rg"
  location              = local.location
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "${local.resource_name}-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_key_vault" "this" {
  name                        = "${local.resource_name}-kv"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  sku_name = "standard"

  network_acls {
    bypass                    = "AzureServices"
    default_action            = "Allow"
  }
}

resource "azurerm_key_vault_certificate" "this" {
  depends_on = [
    azurerm_role_assignment.admin
  ]

  name         = "my-wildcard-pfx-cert"
  key_vault_id = azurerm_key_vault.this.id

  certificate {
    contents = local.certificate_base64_encoded
    password = var.certificate_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id 
}


resource "azurerm_role_assignment" "secrets" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  skip_service_principal_aad_check = true  
}

resource "azurerm_role_assignment" "certs" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  skip_service_principal_aad_check = true  
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.resource_name}-network"
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


resource "azurerm_network_security_group" "this" {
  name                = "${local.resource_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${chomp(data.http.myip.body)}/32"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  name                = "${local.resource_name}-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "this" {
  name                = "${local.resource_name}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "${local.resource_name}-vm"
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
    name                 = "${local.resource_name}-osdisk" 
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
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_mssql_server" "this" {
  name                         = "${local.resource_name}-sql"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = local.location
  version                      = "12.0"
  administrator_login          = "manager"
  administrator_login_password = random_password.password.result
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

resource "azurerm_mssql_firewall_rule" "vm" {
  name             = "AllowAzureVM"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = azurerm_public_ip.this.ip_address
  end_ip_address   = azurerm_public_ip.this.ip_address
}

resource "azurerm_mssql_firewall_rule" "home" {
  name             = "AllowHomeNetwork"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "${chomp(data.http.myip.body)}"
  end_ip_address   = "${chomp(data.http.myip.body)}"
}