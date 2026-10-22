# Azure Managed Redis (not the legacy azurerm_redis_cache resource).
resource "azurerm_managed_redis" "this" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku_name                  = var.sku_name
  high_availability_enabled = var.high_availability_enabled
  public_network_access     = var.public_network_access
  tags                      = var.tags

  default_database {
    # No geo_replication_group_name => active geo-replication is disabled.
    access_keys_authentication_enabled = var.access_keys_authentication
    client_protocol                    = "Encrypted"
    clustering_policy                  = "OSSCluster"
  }
}
