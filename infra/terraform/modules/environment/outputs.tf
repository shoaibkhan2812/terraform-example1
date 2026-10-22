output "resource_group_name" { value = azurerm_resource_group.this.name }
output "linux_service_plan_id" { value = try(azurerm_service_plan.linux[0].id, null) }
output "windows_service_plan_id" { value = try(azurerm_service_plan.windows[0].id, null) }
