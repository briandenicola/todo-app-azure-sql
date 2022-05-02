
resource "azurerm_role_assignment" "admin" {
  scope                     = azurerm_key_vault.this.id
  role_definition_name      = "Key Vault Administrator"
  principal_id              = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "secrets" {
  scope                     = azurerm_key_vault.this.id
  role_definition_name      = "Key Vault Secrets User"
  principal_id              = azurerm_user_assigned_identity.aks_pod_identity.principal_id
  skip_service_principal_aad_check = true  
}

resource "azurerm_role_assignment" "certs" {
  scope                     = azurerm_key_vault.this.id
  role_definition_name      = "Key Vault Certificates Officer"
  principal_id              = azurerm_user_assigned_identity.aks_pod_identity.principal_id
  skip_service_principal_aad_check = true  
}

resource "azurerm_role_assignment" "aks" {
  scope                     = azurerm_virtual_network.this.id
  role_definition_name      = "Network Contributor"
  principal_id              = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_role_assignment_msi" {
  scope                     = azurerm_user_assigned_identity.aks_kubelet_identity.id
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true 
}

resource "azurerm_role_assignment" "aks_role_assignment_pod_identity" {
  scope                     = azurerm_user_assigned_identity.aks_pod_identity.id
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true 
}

resource "azurerm_role_assignment" "azurerm_application_insights" {
  scope                     = azurerm_application_insights.this.id
  role_definition_name      = "Monitoring Metrics Publisher"
  principal_id              = azurerm_user_assigned_identity.aks_pod_identity.principal_id
  skip_service_principal_aad_check = true 
}