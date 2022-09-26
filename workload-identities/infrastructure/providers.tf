terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm  = {
      source = "hashicorp/azurerm"
      version = "3.24.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.18.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

provider "azurerm" {
  features  {}
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.this.kube_config.0.host

    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
    client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_key)
    username               = azurerm_kubernetes_cluster.this.kube_config.0.username
    password               = azurerm_kubernetes_cluster.this.kube_config.0.password
    
  }
}
