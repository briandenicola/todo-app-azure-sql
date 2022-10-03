/*resource "azuread_application" "this" {
  display_name = "${local.aks_name}-${var.namespace}-identity"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "this" {
  application_id               = azuread_application.this.application_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}*/

resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  name                = "${local.aks_name}-${var.namespace}-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}