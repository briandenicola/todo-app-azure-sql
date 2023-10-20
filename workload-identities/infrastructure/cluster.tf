data "azurerm_kubernetes_service_versions" "current" {
  location = azurerm_resource_group.this.location
}

locals {
  kubernetes_version = data.azurerm_kubernetes_service_versions.current.versions[length(data.azurerm_kubernetes_service_versions.current.versions) - 2]
  allowed_ip_range   = ["${chomp(data.http.myip.response_body)}/32"]
  zones              = local.location == "northcentralus" ? null : ["1", "2", "3"]
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_kubernetes_cluster" "this" {
  name                         = local.aks_name
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  node_resource_group          = "${local.resource_name}_k8s_nodes_rg"
  dns_prefix                   = local.aks_name
  sku_tier                     = "Standard"
  automatic_channel_upgrade    = "patch"
  node_os_channel_upgrade      = "NodeImage"
  oidc_issuer_enabled          = true
  workload_identity_enabled    = true
  azure_policy_enabled         = true
  local_account_disabled       = true
  open_service_mesh_enabled    = false
  run_command_enabled          = false
  kubernetes_version           = local.kubernetes_version
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  api_server_access_profile {
    authorized_ip_ranges = local.allowed_ip_range
  }

  linux_profile {
    admin_username = "manager"
    ssh_key {
      key_data = tls_private_key.rsa.public_key_openssh
    }
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = var.vm_sku
    zones               = local.zones
    os_disk_size_gb     = 100
    vnet_subnet_id      = azurerm_subnet.this.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 1
    max_count           = 3
    max_pods            = 40
  }

  network_profile {
    dns_service_ip      = "100.${random_integer.services_cidr.id}.0.10"
    service_cidr        = "100.${random_integer.services_cidr.id}.0.0/16"
    pod_cidr            = "100.${random_integer.pod_cidr.id}.0.0/16"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

}

data "azurerm_public_ip" "aks" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.this.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.this.node_resource_group
}
