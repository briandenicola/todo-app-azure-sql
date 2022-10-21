terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm  = {
      source = "hashicorp/azurerm"
      version = "3.27.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = "0.1.1"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.29.0"
    }
  }
}

provider "azurerm" {
  features  {}
}

provider "azuread" {
}