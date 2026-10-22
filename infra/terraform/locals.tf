locals {
  base_tags = merge(var.tags, { project = var.project_code, managed_by = "terraform" })

  # Keep stable logical for_each keys (e.g. sbox_sw/forgex-TrustAI-API),
  # but convert environment underscores and web app uppercase for Azure names.
  azure_env_names = { for env in var.environments : env => replace(env, "_", "-") }
  storage_env_names = {
    for env in var.environments : env => replace(replace(env, "_", ""), "-", "")
  }

  webapp_instances = {
    for item in flatten([
      for env in var.environments : [
        for app_name in var.webapp_names : {
          key             = "${env}/${app_name}"
          environment     = env
          app_name        = app_name
          azure_name      = "${var.project_code}-${lower(app_name)}-${local.azure_env_names[env]}"
          container_os    = try(var.webapp_settings[app_name].container_os, "Linux")
          acr_name        = coalesce(try(var.webapp_settings[app_name].acr_name, null), startswith(lower(app_name), "forgex-") ? "Forgex" : var.default_acr_name)
          image           = "${coalesce(try(var.webapp_settings[app_name].image_repository, null), lower(app_name))}:${try(var.webapp_settings[app_name].image_tag, "latest")}"
          port            = try(var.webapp_settings[app_name].port, 8080)
          allowed_origins = try(var.webapp_settings[app_name].allowed_origins, [])
        } if length(try(var.webapp_settings[app_name].environments, [])) == 0 || contains(try(var.webapp_settings[app_name].environments, []), env)
      ]
    ]) : item.key => item
  }

  storage_instances = {
    for entry in flatten([
      for env in var.environments : [
        for base_name in var.storage_account_names : {
          key                      = "${env}/${base_name}"
          environment              = env
          base_name                = base_name
          azure_name               = "${base_name}${local.storage_env_names[env]}"
          account_tier             = try(var.storage_settings[base_name].account_tier, "Standard")
          account_replication_type = try(var.storage_settings[base_name].account_replication_type, "LRS")
        }
      ]
    ]) : entry.key => entry
  }

  linux_environments = toset([
    for env in var.environments : env
    if anytrue([for app in values(local.webapp_instances) : app.environment == env && app.container_os == "Linux"])
  ])

  windows_environments = toset([
    for env in var.environments : env
    if anytrue([for app in values(local.webapp_instances) : app.environment == env && app.container_os == "Windows"])
  ])
}

check "names_and_overrides" {
  assert {
    condition     = alltrue([for app in values(local.webapp_instances) : length(app.azure_name) <= 60])
    error_message = "A Web App Azure resource name exceeds 60 characters."
  }
  assert {
    condition     = alltrue([for name in keys(var.webapp_settings) : contains(var.webapp_names, name)])
    error_message = "webapp_settings contains an unknown webapp name."
  }
  assert {
    condition = alltrue(flatten([
      for app in values(var.webapp_settings) : [for env in app.environments : contains(var.environments, env)]
    ]))
    error_message = "webapp_settings.environments must be contained in environments."
  }
  assert {
    condition     = contains(keys(var.acr_resource_groups), var.default_acr_name) && length(setsubtract(var.acr_names, toset(keys(var.acr_resource_groups)))) == 0 && length(setsubtract(toset(keys(var.acr_resource_groups)), var.acr_names)) == 0 && alltrue([for app in values(local.webapp_instances) : contains(keys(var.acr_resource_groups), app.acr_name)])
    error_message = "The ACR names, ACR RG map keys, default ACR and each app ACR selection must match."
  }
  assert {
    condition     = alltrue([for name in keys(var.storage_settings) : contains(var.storage_account_names, name)])
    error_message = "storage_settings contains an unknown account base name."
  }
  assert {
    condition     = alltrue([for account in values(local.storage_instances) : length(account.azure_name) >= 3 && length(account.azure_name) <= 24])
    error_message = "A computed storage account name must be between 3 and 24 lowercase alphanumeric characters."
  }
  assert {
    condition     = length(distinct([for account in values(local.storage_instances) : account.azure_name])) == length(local.storage_instances)
    error_message = "Two storage accounts would have the same Azure name."
  }
}
