output "APP_NAME" {
  value     = local.resource_name
  sensitive = false
}

output "AKS_RESOURCE_GROUP" {
  value     = azurerm_kubernetes_cluster.this.resource_group_name
  sensitive = false
}

output "AKS_CLUSTER_NAME" {
  value     = azurerm_kubernetes_cluster.this.name
  sensitive = false
}

output "AKS_OUTBOUND_IP" {
  value     = data.azurerm_public_ip.aks.ip_address
  sensitive = false
}

output "AKS_NODE_POOL_IDENTITY" {
  value     = "${azurerm_kubernetes_cluster.this.name}-agentpool"
  sensitive = false
}

output "ARM_WORKLOAD_APP_ID" {
  value     = azurerm_user_assigned_identity.aks_pod_identity.client_id
  sensitive = false
}

output "ARM_TENANT_ID" {
  value     = azurerm_user_assigned_identity.aks_pod_identity.tenant_id
  sensitive = false
}

output "APP_INSIGHTS" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}

output "MANAGED_IDENTITY_NAME" {
  value     = azurerm_user_assigned_identity.aks_pod_identity.name
  sensitive = false
}

output "SQL_SERVER_FQDN" {
  value     = azurerm_mssql_server.this.fully_qualified_domain_name
  sensitive = false
}

output "SQL_SERVER_NAME" {
  value     = azurerm_mssql_server.this.name
  sensitive = false
}
