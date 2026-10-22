output "webapp_names" {
  value       = { for key, app in module.webapp : key => app.name }
  description = "Web app names keyed by environment/logical app name."
}
output "webapp_urls" {
  value = { for key, app in module.webapp : key => app.url }
}
output "webapp_principal_ids" {
  value = { for key, app in module.webapp : key => app.principal_id }
}
output "webapp_acr_assignments" {
  value = { for key, app in local.webapp_instances : key => app.acr_name }
}
output "existing_acr_login_servers" {
  value       = { for name, registry in data.azurerm_container_registry.existing : name => registry.login_server }
  description = "Read-only existing container registries; never provisioned by this state."
}
output "storage_account_names" {
  value = { for key, account in module.storage : key => account.name }
}
output "resource_groups" {
  value = { for env, rg in module.environment : env => rg.resource_group_name }
}
output "postgres_names" {
  value = { for env, db in module.postgres : env => db.name }
}
output "postgres_fqdns" {
  value = { for env, db in module.postgres : env => db.fqdn }
}
output "redis_names" {
  value = { for env, cache in module.redis : env => cache.name }
}
output "redis_hosts" {
  value = { for env, cache in module.redis : env => cache.hostname }
}
