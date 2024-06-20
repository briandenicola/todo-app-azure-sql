resource "azurerm_mssql_server" "this" {
  name                         = local.sql_server_name
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

resource "azurerm_mssql_firewall_rule" "vm" {
  name             = "AllowAzureVM"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = azurerm_public_ip.this.ip_address
  end_ip_address   = azurerm_public_ip.this.ip_address
}

resource "azurerm_mssql_firewall_rule" "home" {
  name             = "AllowHomeNetwork"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "${chomp(data.http.myip.response_body)}"
  end_ip_address   = "${chomp(data.http.myip.response_body)}"
}