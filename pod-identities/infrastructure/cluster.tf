resource "azurerm_kubernetes_cluster" "this" {
  name                      = "${local.aks_name}"
  resource_group_name       = azurerm_resource_group.this.name
  location                  = azurerm_resource_group.this.location
  node_resource_group       = "${local.resource_name}_k8s_nodes_rg"
  dns_prefix                = "${local.aks_name}"
  sku_tier                  = "Paid"
  api_server_authorized_ip_ranges = ["${chomp(data.http.myip.body)}/32"]

  identity {
    type                      = "UserAssigned"
    identity_ids              = [ azurerm_user_assigned_identity.aks_identity.id ]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet_identity.id
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

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

}

resource "azapi_update_resource" "this" {
  depends_on = [
    azurerm_kubernetes_cluster.this
  ]

  type        = "Microsoft.ContainerService/managedClusters@2021-07-01"
  resource_id = azurerm_kubernetes_cluster.this.id

  body = jsonencode({
    properties = {
      podIdentityProfile = {
        enabled = true
      }
    }
  })
}