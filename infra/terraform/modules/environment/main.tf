resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_code}-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_service_plan" "linux" {
  count               = var.linux_plan_needed ? 1 : 0
  name                = "asp-${var.project_code}-linux-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.linux_plan_sku
  tags                = var.tags
}

resource "azurerm_service_plan" "windows" {
  count               = var.windows_plan_needed ? 1 : 0
  name                = "asp-${var.project_code}-windows-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  os_type             = "Windows"
  sku_name            = var.windows_plan_sku
  tags                = var.tags
}
