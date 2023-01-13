output "APP_NAME" {
    value = local.resource_name
    sensitive = false
}

output "AKS_RESOURCE_GROUP" {
    value = azurerm_kubernetes_cluster.this.resource_group_name
    sensitive = false
}

output "AKS_CLUSTER_NAME" {
    value = azurerm_kubernetes_cluster.this.name
    sensitive = false
}

output "AKS_OUTBOUND_IP" {
    value = data.azurerm_public_ip.aks.ip_address
    sensitive = false
}

output "AKS_NODE_POOL_IDENTITY" {
    value = azurerm_user_assigned_identity.aks_kubelet_identity.name
    sensitive = false
}

output "MSI_CLIENTID" {
    value = azurerm_user_assigned_identity.aks_pod_identity.client_id
    sensitive = false
}

output "MSI_SELECTOR" {
    value = azurerm_user_assigned_identity.aks_pod_identity.name
    sensitive = false
}

output "APP_INSIGHTS" {
    value = azurerm_application_insights.this.connection_string
    sensitive = true
}

