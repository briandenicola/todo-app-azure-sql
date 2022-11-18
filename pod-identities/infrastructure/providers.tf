terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm  = {
      source = "hashicorp/azurerm"
      version = "3.31.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "1.1.0"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}