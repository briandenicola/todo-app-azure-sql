resource "helm_release" "azure-workload-identity" {
  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
  name              = "azure-workload-identity"
  repository        = "https://azure.github.io/azure-workload-identity/charts"
  chart             = "workload-identity-webhook"
  namespace         = "azure-workload-identity-system"
  create_namespace  = true

  set {
    name  = "azureTenantID"
    value = data.azurerm_client_config.current.tenant_id
  }
}

