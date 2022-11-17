resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  name                = local.workload-identity
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

//https://github.com/hashicorp/terraform-provider-azurerm/issues/18617
#resource "azapi_resource" "federated_identity_credential" {
#  schema_validation_enabled = false
#  name                      = local.workload-identity
#  parent_id                 = azurerm_user_assigned_identity.aks_pod_identity.id
#  type                      = "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2022-01-31-preview"
#
#  location                  = local.location
#  body = jsonencode({
#    properties = {
#      issuer    = azurerm_kubernetes_cluster.this.oidc_issuer_url
#      subject   = "system:serviceaccount:${var.namespace}:${local.workload-identity}"
#      audiences = ["api://AzureADTokenExchange"]
#    }
#  })
#}

resource "azurerm_federated_identity_credential" "aks_pod_identity" {
  name                = local.workload-identity
  resource_group_name = azurerm_resource_group.this.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.aks_pod_identity.id
  subject             = "system:serviceaccount:${var.namespace}:${local.workload-identity}"
}