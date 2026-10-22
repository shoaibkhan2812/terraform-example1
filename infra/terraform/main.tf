# Only environments listed in `environments` are created or managed.
# dev/sbox_sw are deliberately absent; do NOT create/import them here.
module "environment" {
  source   = "./modules/environment"
  for_each = var.environments

  project_code        = var.project_code
  environment         = local.azure_env_names[each.key]
  location            = var.location
  linux_plan_needed   = contains(local.linux_environments, each.key)
  windows_plan_needed = contains(local.windows_environments, each.key)
  linux_plan_sku      = var.linux_plan_sku
  windows_plan_sku    = var.windows_plan_sku
  tags                = merge(local.base_tags, { environment = each.key })
}

# Existing, out-of-state ACRs: read ONLY, never create, update, or destroy them.
# Each registry can belong to a DIFFERENT existing resource group.
data "azurerm_container_registry" "existing" {
  for_each            = var.acr_resource_groups
  name                = each.key
  resource_group_name = each.value
}

module "webapp" {
  source   = "./modules/webapp"
  for_each = local.webapp_instances

  name                = each.value.azure_name
  resource_group_name = module.environment[each.value.environment].resource_group_name
  location            = var.location
  container_os        = each.value.container_os
  service_plan_id     = each.value.container_os == "Linux" ? module.environment[each.value.environment].linux_service_plan_id : module.environment[each.value.environment].windows_service_plan_id
  acr_id              = data.azurerm_container_registry.existing[each.value.acr_name].id
  acr_login_server    = data.azurerm_container_registry.existing[each.value.acr_name].login_server
  image               = each.value.image
  port                = each.value.port
  allowed_origins     = each.value.allowed_origins
  tags                = merge(local.base_tags, { environment = each.value.environment, app = each.value.app_name, acr = each.value.acr_name })
}

module "storage" {
  source   = "./modules/storage"
  for_each = local.storage_instances

  name                     = each.value.azure_name
  resource_group_name      = module.environment[each.value.environment].resource_group_name
  location                 = var.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  tags                     = merge(local.base_tags, { environment = each.value.environment, storage = each.value.base_name })
}

module "postgres" {
  source   = "./modules/postgres"
  for_each = var.environments

  name                          = "${var.postgres_name_prefix}-${local.azure_env_names[each.key]}"
  resource_group_name           = module.environment[each.key].resource_group_name
  location                      = var.location
  sku_name                      = var.postgres_sku_name
  version                       = var.postgres_version
  availability_zone             = var.postgres_availability_zone
  admin_username                = var.postgres_admin_username
  admin_password                = var.postgres_admin_password
  storage_mb                    = var.postgres_storage_mb
  backup_retention_days         = var.postgres_backup_retention_days
  public_network_access_enabled = var.postgres_public_network_access_enabled
  firewall_rules                = var.postgres_firewall_rules
  tags                          = merge(local.base_tags, { environment = each.key })
}

module "redis" {
  source   = "./modules/redis"
  for_each = var.environments

  name                        = "${var.redis_name_prefix}-${local.azure_env_names[each.key]}"
  resource_group_name         = module.environment[each.key].resource_group_name
  location                    = var.location
  sku_name                    = var.redis_sku_name
  high_availability_enabled   = var.redis_high_availability_enabled
  public_network_access       = var.redis_public_network_access
  access_keys_authentication  = var.redis_access_keys_authentication_enabled
  tags                        = merge(local.base_tags, { environment = each.key })
}
