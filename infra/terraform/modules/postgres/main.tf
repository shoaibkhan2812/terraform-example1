resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.version
  sku_name                      = var.sku_name
  zone                          = var.availability_zone
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  # High availability for PostgreSQL has NOT been specified; it is not enabled here.
  # Public endpoint creation does NOT itself allow client IPs; see firewall_rules.
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allowlisted" {
  for_each         = var.firewall_rules
  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}
