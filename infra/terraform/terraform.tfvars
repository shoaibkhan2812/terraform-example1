# CONFIGURATION FOR NEW, TERRAFORM-MANAGED ENVIRONMENTS ONLY.
# Existing manually created dev/sbox_sw are deliberately excluded.
# To provision another NEW environment, append it after verifying names do not already exist.
project_code = "aero"
location     = "centralindia"
environments = ["qa"]

webapp_names = [
  "auth",
  "br-ai",
  "cu",
  "forge-ai",
  "forge-ui",
  "pmo-ai",
  "pmo-ui",
  "processiq-ai",
  "qe-ai",
  "sopbuild-ai",
  "sbsm-ai",
  "blueswanqe-ui",
  "forgex-arch",
  "forgex-ba",
  "forgex-codedev",
  "forgex-kb",
  "forgex-po",
  "forgex-qe",
  "forgex-workflow",
  "forgex-LLMRouter-API",
  "forgex-TrustAI-API",
  "forgex-TrustAI-benckmarck",
  "forgex-trustai-qag",
  "forgex-TrustAI-UI",
  "forgex-ui",
]

# Registries exist already. Supply THEIR ACTUAL resource-group names here.
# Nothing in this project creates/imports/alters these registry resources.
acr_names        = ["Forgex", "aeronova"]
default_acr_name = "aeronova"
acr_resource_groups = {
  Forgex   = "REPLACE_WITH_FORGEX_ACR_RESOURCE_GROUP"
  aeronova = "REPLACE_WITH_AERONOVA_ACR_RESOURCE_GROUP"
}

# Creates forgexqa; existing forgexdev and forgexsboxsw remain untouched.
storage_account_names = ["forgex"]
storage_settings = {
  forgex = { account_tier = "Standard", account_replication_type = "LRS" }
}

# One shared plan per OS per NEW environment.
linux_plan_sku   = "P3v3"
windows_plan_sku = "P3v3"

# Per-app overrides: default Linux, <logical-name>:latest, port 8080, CORS [].
# forgex-* -> Forgex, otherwise -> aeronova unless acr_name is set here.
webapp_settings = {
  # auth = {
  #   container_os     = "Linux"
  #   acr_name         = "aeronova"
  #   image_repository = "auth"
  #   image_tag        = "v1"
  #   port             = 8080
  #   allowed_origins  = ["https://qa.example.com"]
  # }
}

# PostgreSQL Flexible Server: forgex-postgres-qa
postgres_name_prefix                 = "forgex-postgres"
postgres_sku_name                    = "GP_Standard_D4ds_v5"
postgres_version                     = "17"
postgres_availability_zone           = "1"
postgres_admin_username             = "postgresaadmin"
# postgres_admin_password: GitHub secret POSTGRES_ADMIN_PASSWORD (not this file).
postgres_storage_mb                  = 32768 # 32 GiB temporary default; confirm requirements.
postgres_backup_retention_days       = 7
postgres_public_network_access_enabled = true
postgres_firewall_rules              = {} # No IP allowlist -> cannot connect until rules/network are added.

# Managed Redis: forrgex-redis-qa (preserves exact double-r spelling).
redis_name_prefix                       = "forrgex-redis"
redis_sku_name                          = "Balanced_B1" # 1 GB
redis_high_availability_enabled         = true
redis_public_network_access             = "Enabled"
redis_access_keys_authentication_enabled = true
# Geo-replication is absent/disabled.

tags = {
  system = "aero"
  owner  = "platform-team"
}
