terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm  = {
      source = "hashicorp/azurerm"
      version = "3.3.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.18.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
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

    /*exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = [
        "get-token", 
         "--environment", 
        "AzurePublicCloud",
        "--server-id", 
        "6dae42f8-4368-4678-94ff-3960e28e3630", 
       "--client-id", 
        "80faf920-1908-4b52-b5ef-a8e7bedfc67a",
        "--tenant-id",
        data.azurerm_client_config.current.tenant_id
     ]
      command     = "kubelogin"
    }*/
  }
}