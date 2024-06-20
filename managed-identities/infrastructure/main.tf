data "azurerm_client_config" "current" {}

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

resource "random_id" "this" {
  byte_length = 2
}

resource "random_pet" "this" {
  length    = 1
  separator = ""
}

resource "random_integer" "vnet_cidr" {
  min = 10
  max = 250
}

resource "random_password" "password" {
  length  = 25
  special = true
}

locals {
  location        = var.region
  resource_name   = "${random_pet.this.id}-${random_id.this.dec}"
  vm_name         = "${replace(local.resource_name, "-", "")}vm"
  sql_server_name = "${local.resource_name}-sql"
  bastion_name    = "${local.resource_name}-bastion"
  nat_name        = "${local.resource_name}-nat"
  vnet_cidr       = cidrsubnet("10.0.0.0/8", 8, random_integer.vnet_cidr.result)
  subnet_cidir    = cidrsubnet(local.vnet_cidr, 8, 2)
}

resource "azurerm_resource_group" "this" {
  name     = "${local.resource_name}_rg"
  location = local.location

  tags = {
    Application = "Todo Demo App"
    Components  = "vm; key vault; azure-sql; managed-identities"
    DeployedOn  = timestamp()
  }
}
