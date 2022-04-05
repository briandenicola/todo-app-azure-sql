terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm  = {
      source = "hashicorp/azurerm"
      version = "2.98.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.18.0"
    }
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
    aks_name                    = "${local.resource_name}-aks"
}

resource "azuread_application" "this" {
  display_name = "${local.aks_name}-${var.namespace}-identity"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "this" {
  application_id               = azuread_application.this.application_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}
    
resource "azurerm_resource_group" "this" {
  name                  = "${local.resource_name}_rg"
  location              = local.location
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
  principal_id         = azuread_service_principal.this.object_id
  skip_service_principal_aad_check = true  
}

resource "azurerm_role_assignment" "certs" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azuread_service_principal.this.object_id
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
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = "${local.aks_name}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  node_resource_group       = "${local.resource_name}_k8s_nodes_rg"
  dns_prefix                = "${local.aks_name}"
  sku_tier                  = "Paid"
  api_server_authorized_ip_ranges = ["${chomp(data.http.myip.body)}/32"]

  identity {
    type                    = "SystemAssigned"
  }

  default_node_pool  {
    name                    = "default"
    node_count              = 3
    vm_size                = "Standard_DS2_v2"
    os_disk_size_gb         = 30
    vnet_subnet_id          = azurerm_subnet.this.id
    type                    = "VirtualMachineScaleSets"
    enable_auto_scaling     = true
    min_count               = 3
    max_count               = 10
    max_pods                = 40
  }

  role_based_access_control {
    enabled                 = "true"
  }

  network_profile {
    dns_service_ip          = "10.190.0.10"
    service_cidr            = "10.190.0.0/16"
    docker_bridge_cidr      = "172.17.0.1/16"
    network_plugin          = "azure"
    load_balancer_sku       = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

}

resource "azurerm_resource_group_template_deployment" "this" {
  depends_on = [
     azurerm_kubernetes_cluster.this
  ]

  name                = "post-cluster-setup"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  parameters_content  = jsonencode({
    "aksCluster"      = {
      value = local.aks_name
    },
    "logAnalyticsId"  = {
      value = azurerm_log_analytics_workspace.this.id
    }
  })
  template_content = <<TEMPLATE
    {
      "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {
        "aksCluster": {
          "type": "string"
        },
        "logAnalyticsId": {
          "type": "string"
        }
      },
      "resources": [
        { 
          "type": "Microsoft.ContainerService/managedClusters", 
          "apiVersion": "2021-07-01", 
          "name": "[parameters('aksCluster')]", 
          "location": "[resourceGroup().location]",
          "properties": {
            "oidcIssuerProfile": {
              "enabled": true
            },
            "securityProfile": { 
              "azureDefender": { 
                "enabled": true, 
                "logAnalyticsWorkspaceResourceId": "[parameters('logAnalyticsId')]"
              }
            }
          }
        }
      ]
    }
TEMPLATE
}

resource "azurerm_role_assignment" "aks" {
  scope                = azurerm_virtual_network.this.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
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

resource "azurerm_mssql_firewall_rule" "home" {
  name             = "AllowHomeNetwork"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "${chomp(data.http.myip.body)}"
  end_ip_address   = "${chomp(data.http.myip.body)}"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.resource_name}-logs"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "pergb2018"
}

resource "azurerm_log_analytics_solution" "this" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_application_insights" "this" {
  name                = "${local.resource_name}-appinsights"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
}