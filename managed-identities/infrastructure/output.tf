output "APP_NAME" {
  value     = local.resource_name
  sensitive = false
}

output "APP_RESOURCE_GROUP" {
  value     = azurerm_resource_group.this.name
  sensitive = false
}

output "ARM_WORKLOAD_APP_ID" {
  value     = azurerm_user_assigned_identity.this.client_id
  sensitive = false
}

output "ARM_TENANT_ID" {
  value     = azurerm_user_assigned_identity.this.tenant_id
  sensitive = false
}

output "MANAGED_IDENTITY_NAME" {
  value     = azurerm_user_assigned_identity.this.name
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