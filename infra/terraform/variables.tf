variable "subscription_id" {
  description = "Provided by TF_VAR_subscription_id via GitHub Actions. Do not commit secrets."
  type        = string
}

variable "project_code" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,11}$", var.project_code)) && !endswith(var.project_code, "-")
    error_message = "project_code must start with a lowercase letter and be <= 12 lowercase letters/digits/hyphens."
  }
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "environments" {
  description = "Environment keys may contain underscores or hyphens; names are normalized by target service."
  type        = set(string)
  validation {
    condition = length(var.environments) > 0 && alltrue([
      for env in var.environments : can(regex("^[a-z]([a-z0-9_-]{0,18}[a-z0-9])?$", env))
    ]) && length(distinct([for env in var.environments : replace(env, "_", "-")])) == length(var.environments) && length(distinct([
      for env in var.environments : replace(replace(env, "_", ""), "-", "")
    ])) == length(var.environments)
    error_message = "Environment keys must be valid, and must not collide after removing _ or - for storage names."
  }
}

variable "webapp_names" {
  description = "Logical names, case preserved here; Azure names and default Docker image repositories are lowercase."
  type        = set(string)
  validation {
    condition = length(var.webapp_names) > 0 && alltrue([
      for name in var.webapp_names : can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,44}$", name)) && !endswith(name, "-")
      ]) && length(distinct([for name in var.webapp_names : lower(name)])) == length(var.webapp_names)
    error_message = "Webapp names must be unique ignoring case, 1-45 characters, and contain only letters/digits/hyphens."
  }
}

variable "acr_names" {
  description = "Names of the EXISTING ACRs used for registry routing (not created by Terraform)."
  type        = set(string)
  validation {
    condition = length(var.acr_names) > 0 && alltrue([
      for name in var.acr_names : can(regex("^[A-Za-z0-9]{5,50}$", name))
      ]) && length(distinct([for name in var.acr_names : lower(name)])) == length(var.acr_names)
    error_message = "ACR names must be 5-50 alphanumeric chars and unique ignoring case."
  }
}

variable "default_acr_name" {
  type        = string
  description = "ACR used for apps without a specific ACR override or the forgex- naming prefix."
}

variable "webapp_settings" {
  description = "Per-application overrides. acr_name selects exactly one registry, granting the identity AcrPull to it."
  type = map(object({
    container_os     = optional(string, "Linux")
    acr_name         = optional(string)
    image_repository = optional(string)
    image_tag        = optional(string, "latest")
    port             = optional(number, 8080)
    allowed_origins  = optional(list(string), [])
    environments     = optional(list(string), [])
  }))
  default = {}
  validation {
    condition = alltrue([
      for name, app in var.webapp_settings :
      contains(["Linux", "Windows"], app.container_os) &&
      app.port >= 1 && app.port <= 65535 &&
      length(app.image_tag) > 0 &&
      (app.image_repository == null || length(app.image_repository) > 0)
    ])
    error_message = "Invalid webapp_settings: container_os must be Linux/Windows; port 1-65535; image/tag nonempty."
  }
}

variable "storage_account_names" {
  description = "Names without environment; a storage account is created for every listed environment."
  type        = set(string)
  validation {
    condition = alltrue([
      for name in var.storage_account_names : can(regex("^[a-z][a-z0-9]{1,23}$", name))
    ])
    error_message = "Storage base names must contain lowercase letters/numbers and start with a letter."
  }
}

variable "storage_settings" {
  description = "Optional configuration keyed by base storage-account name."
  type = map(object({
    account_replication_type = optional(string, "LRS")
    account_tier             = optional(string, "Standard")
  }))
  default = {}
  validation {
    condition = alltrue([
      for name, cfg in var.storage_settings :
      contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], cfg.account_replication_type) &&
      contains(["Standard", "Premium"], cfg.account_tier)
    ])
    error_message = "Invalid storage account tier or replication option. Check which combinations are available in Central India."
  }
}

variable "linux_plan_sku" {
  type    = string
  default = "P3v3"
}
variable "windows_plan_sku" {
  type    = string
  default = "P3v3"
}
variable "tags" {
  type    = map(string)
  default = {}
}


# Existing ACR names and their resource groups. Names MUST match acr_names exactly.
variable "acr_resource_groups" {
  description = "Existing ACR name -> existing Azure resource group. Neither will be created or imported."
  type        = map(string)
  validation {
    condition     = length(var.acr_resource_groups) > 0 && alltrue([for rg in values(var.acr_resource_groups) : length(trimspace(rg)) > 0 && !startswith(rg, "REPLACE_")])
    error_message = "Set the actual Azure resource-group name for each existing ACR in acr_resource_groups."
  }
}

variable "postgres_name_prefix" {
  type    = string
  default = "forgex-postgres"
}
variable "postgres_sku_name" {
  description = "General Purpose D4ds_v5: GP_Standard_D4ds_v5."
  type        = string
  default     = "GP_Standard_D4ds_v5"
}
variable "postgres_version" {
  type    = string
  default = "17"
}
variable "postgres_availability_zone" {
  type    = string
  default = "1"
}
variable "postgres_admin_username" {
  type    = string
  default = "postgresaadmin"
}
variable "postgres_admin_password" {
  description = "Pass through GitHub repository secret POSTGRES_ADMIN_PASSWORD -> TF_VAR_postgres_admin_password. Never commit this value."
  type        = string
  sensitive   = true
  ephemeral   = false
  validation {
    condition     = length(var.postgres_admin_password) >= 12
    error_message = "Use a strong PostgreSQL administrator password of at least 12 characters."
  }
}
variable "postgres_storage_mb" {
  description = "Storage size placeholder: 32768 MiB = 32 GiB; customize before provisioning."
  type        = number
  default     = 32768
}
variable "postgres_backup_retention_days" {
  type    = number
  default = 7
  validation {
    condition     = var.postgres_backup_retention_days >= 7 && var.postgres_backup_retention_days <= 35
    error_message = "PostgreSQL backup retention must be between 7 and 35 days."
  }
}
variable "postgres_public_network_access_enabled" {
  description = "Public network endpoint allowed. With an empty firewall_rules map, no client IP is allowlisted. Private networking should be designed later."
  type        = bool
  default     = true
}
variable "postgres_firewall_rules" {
  description = "Explicit allowed public client-IP rules; empty for initial creation. Avoid 0.0.0.0 Azure-services wildcard."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "redis_name_prefix" {
  description = "Name prefix as requested, including the double-r in forrgex."
  type        = string
  default     = "forrgex-redis"
}
variable "redis_sku_name" {
  description = "Balanced_B1 is 1 GB of Azure Managed Redis."
  type        = string
  default     = "Balanced_B1"
}
variable "redis_high_availability_enabled" {
  type    = bool
  default = true
}
variable "redis_public_network_access" {
  type    = string
  default = "Enabled"
  validation {
    condition     = contains(["Enabled", "Disabled"], var.redis_public_network_access)
    error_message = "redis_public_network_access must be Enabled or Disabled."
  }
}
variable "redis_access_keys_authentication_enabled" {
  description = "Temporary key authentication for application integration; prefer Entra ID auth later. Keys will be kept in Terraform state."
  type        = bool
  default     = true
}
