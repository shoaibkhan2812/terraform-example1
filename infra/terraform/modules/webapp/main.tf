# A Linux container web app (or Windows when explicitly configured),
# with system-assigned managed identity and ACRPull.
resource "azurerm_linux_web_app" "this" {
  count = var.container_os == "Linux" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.2"
    ftps_state                              = "Disabled"

    application_stack {
      docker_image_name   = var.image
      docker_registry_url = "https://${var.acr_login_server}"
    }

    dynamic "cors" {
      for_each = length(var.allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.allowed_origins
        support_credentials = false
      }
    }
  }

  app_settings = { WEBSITES_PORT = tostring(var.port) }
  tags         = var.tags
}

resource "azurerm_windows_web_app" "this" {
  count = var.container_os == "Windows" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.service_plan_id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    container_registry_use_managed_identity = true
    minimum_tls_version                     = "1.2"
    ftps_state                              = "Disabled"

    application_stack {
      docker_image_name   = var.image
      docker_registry_url = "https://${var.acr_login_server}"
    }

    dynamic "cors" {
      for_each = length(var.allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.allowed_origins
        support_credentials = false
      }
    }
  }

  app_settings = { WEBSITES_PORT = tostring(var.port) }
  tags         = var.tags
}

locals {
  principal_id = var.container_os == "Linux" ? azurerm_linux_web_app.this[0].identity[0].principal_id : azurerm_windows_web_app.this[0].identity[0].principal_id
  hostname     = var.container_os == "Linux" ? azurerm_linux_web_app.this[0].default_hostname : azurerm_windows_web_app.this[0].default_hostname
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = local.principal_id
  skip_service_principal_aad_check = true
}
