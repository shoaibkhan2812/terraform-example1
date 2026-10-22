# Aero Terraform — Phase 3: new QA + existing ACRs + PostgreSQL 17 + Azure Managed Redis

This is a **replacement** for the phase-2 starter. All resources are in **Central India** (`centralindia`). **Nothing has been applied to Azure from this package.**

## What will be managed

| Resource | QA name/configuration | Terraform behavior |
| --- | --- | --- |
| Resource group | `rg-aero-qa` | Create |
| Linux App Service plan | `asp-aero-linux-qa`, `P3v3` | Create (shared by the 25 Linux web apps) |
| Web apps | 25 × `aero-<lowercase-app>-qa` | Create, system-assigned identities and `AcrPull` |
| Container Registries | `Forgex`, `aeronova` | **Read-only data sources** (existing resources) |
| Application Storage | `forgexqa`, Standard LRS | Create |
| PostgreSQL Flexible Server | `forgex-postgres-qa`, v17, `GP_Standard_D4ds_v5`, zone `1` | Create |
| Azure Managed Redis | `forrgex-redis-qa`, `Balanced_B1`, 1 GiB, HA, public network access | Create |

**Manual `dev` and `sbox_sw` resources are EXCLUDED.** Only environments in `infra/terraform/terraform.tfvars` -> `environments = ["qa"]` are managed. An extra new environment can be added to this list later, but never put existing manually managed environments in this list without importing/migrating the relevant resources. A new entry expands *all* new resources in this root state.

**Naming:** env `_` becomes `-` in webapps/DB/Redis; storage removes `_` and `-`. `forrgex` is intentionally spelled with double `r` per request; change `redis_name_prefix` to `forgex-redis` if that was a typo.

## Where to change the settings

Everything non-secret is in **`infra/terraform/terraform.tfvars`** (see comments):

| Input | Current placeholder | Meaning |
| --- | --- | --- |
| `environments` | `["qa"]` | Only create these *new* environments |
| `acr_resource_groups` | `REPLACE_WITH_...` | **Must fill** actual RG for each existing registry |
| `linux_plan_sku` / `windows_plan_sku` | `P3v3` | Shared App Service Plan sizes |
| `postgres_name_prefix` | `forgex-postgres` | Prefix before `-qa` |
| `postgres_sku_name` | `GP_Standard_D4ds_v5` | General Purpose D4ds_v5 |
| `postgres_version` | `17` | PostgreSQL major version |
| `postgres_availability_zone` | `1` | Availability zone |
| `postgres_admin_username` | `postgresaadmin` | Login name, unchanged |
| `postgres_storage_mb` | `32768` | **Assumed** 32 GiB; confirm |
| `postgres_backup_retention_days` | `7` | **Assumed** 7 days; confirm |
| `postgres_public_network_access_enabled` | `true` | Public endpoint, but no client IP firewall rules allowed by default |
| `postgres_firewall_rules` | `{}` | Explicit allowed client IPs; start empty; add narrowly scoped rules or plan VNet/private access |
| `redis_name_prefix` | `forrgex-redis` | Preserves requested double-r spelling |
| `redis_sku_name` | `Balanced_B1` | 1 GiB (the SKU determines memory) |
| `redis_high_availability_enabled` | `true` | HA nodes |
| `redis_public_network_access` | `Enabled` | Public connectivity; secure authentication required |
| `redis_access_keys_authentication_enabled` | `true` | Assumed for first application integration; consider Entra auth later |
| `webapp_names`, `webapp_settings` | 25 apps | Logical app names, OS, image, CORS, port and ACR routing |

### IMPORTANT: passwords and Terraform state

The sample string supplied for PostgreSQL was a **placeholder**, not an acceptable password for production. **No administrator password is stored in this repo**. Add a strong value (unique, long, mixed character classes) as GitHub *repository Actions secret* `POSTGRES_ADMIN_PASSWORD`, which becomes `TF_VAR_postgres_admin_password` in the plan job. The sensitive password is nevertheless included in **Terraform state and a binary plan**; protect your Azure state container with access controls and blob versioning. The plan artifact is **encrypted** with a separate secret and expires after 3 days. Never upload the plaintext plan to a PR, logs or unprotected artifact.

PostgreSQL **high availability** was *not specified* and is not configured. Redis HA is enabled. PostgreSQL public access defaults to an endpoint with **no firewall allowlist**, so applications cannot connect until network rules/private networking are designed. Azure Managed Redis public access was specifically requested; use TLS and either auth keys or Entra ID and plan appropriate network isolation for production. Do not automatically whitelist 0.0.0.0 for PostgreSQL.

The Redis default database uses TLS (`Encrypted`) and OSSCluster, with access keys enabled as a practical starting assumption. **No geo-replication group** is configured.

The 25 app image names and tags default to `*:latest` and port `8080`; verify which images exist in each registry **before** applying. Routing assumption: `forgex-*` -> Forgex, remaining -> aeronova, override `webapp_settings` if needed. Existing registries must use legacy RBAC role assignment permission mode for `AcrPull`; if ABAC-enabled, change to Container Registry Repository Reader as appropriate instead of modifying the registry blindly.

## Setup: Existing ACR RG names

Get the REAL Azure resource groups and verify access:

```bash
az acr show --name Forgex --query '{name:name,resourceGroup:resourceGroup,id:id}' -o json
az acr show --name aeronova --query '{name:name,resourceGroup:resourceGroup,id:id}' -o json
```

Put the two resource-group names in `infra/terraform/terraform.tfvars`:

```hcl
acr_resource_groups = {
  Forgex   = "your-forgex-registry-rg"
  aeronova = "your-aeronova-registry-rg"
}
```

Nothing imports or creates the ACRs; `data.azurerm_container_registry.existing` reads their IDs and login servers. The managed identities of NEW QA webapps receive `AcrPull` on the chosen existing registries. ACRs might use different RGs. State RBAC for the existing registries may need elevated permissions to assign roles.

## GitHub Actions plan and apply approval

- `.github/workflows/terraform-check.yml`: pull request formatting/validation (no Azure access).
- `.github/workflows/terraform-apply.yml`: on `main` push or manual run, `plan` uses existing Entra app registration / Service Principal OIDC, saves a Terraform plan, prints a human-readable plan in workflow logs, then encrypts and uploads the **binary** plan for a maximum of one day. The `apply` job waits for **GitHub Environment `aero-infra-apply` required reviewers**, decrypts the plan, and applies *exactly* that saved plan.

**Required GitHub setup** (Settings → Environments → `aero-infra-apply`): turn on **Required reviewers** and deploy branch restrictions (`main`), ideally *prevent self-review*. IMPORTANT: Merely naming a GitHub environment in YAML does NOT enforce approval. Availability of reviewers for private repositories depends on your GitHub plan; confirm your repository supports this rule before trusting the workflow. Do not enable the workflow until the gate is in place.

GitHub **repository Actions variables**:

- `AERO_APPLY_ENABLED` = `true` **only after required reviewers and branch restrictions are configured**; when absent/false, the plan runs but apply is skipped.

- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
- `TFSTATE_RESOURCE_GROUP`, `TFSTATE_STORAGE_ACCOUNT`, `TFSTATE_CONTAINER` (existing remote Terraform state storage)

GitHub **repository Actions secrets**:

- `POSTGRES_ADMIN_PASSWORD` — strong administrator password (plan job only).
- `TF_PLAN_ENCRYPTION_PASSWORD` — a *different* high-entropy passphrase; used to encrypt binary plan between jobs.

Set **two federated credentials** for your *existing service principal* (same issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`):

1. Plan job (no environment): `repo:ORG/REPO:ref:refs/heads/main`
2. Apply job (protected environment): `repo:ORG/REPO:environment:aero-infra-apply`

Replace `ORG/REPO` with your GitHub organization/repo. Existing SP must have Contributor or appropriate resource-write permissions to `rg-aero-qa` creation scope and **Role Based Access Control Administrator** (or another role granting `Microsoft.Authorization/roleAssignments/write`) on both ACR scopes. Backend access also needs **Storage Blob Data Contributor** at the backend state container. Prefer least-privilege scoping.

Bootstrap remote state separately via `scripts/bootstrap-state.sh`; DO NOT use `forgexqa` as the state account. Both CI jobs use blob `aero/new-environments.tfstate`. Do not mix states from earlier phases without reviewing resources already recorded there; **a state with phase-2 resources will propose destroying those resources** because they are no longer present in this phase. For an entirely new project, use a fresh backend key/state (the template uses a NEW `aero/new-environments.tfstate` key to avoid modifying state from prior phases; do not change it independently across jobs).

### Sequence

1. Fill ACR resource group names, verify ACR RBAC mode, check Azure quota/region SKU availability.
2. Confirm PostgreSQL network, storage, HA needs, and Redis authentication choice.
3. Put GitHub variables/secrets in Settings, configure OIDC credentials and protected environment.
4. Bootstrap backend or connect existing backend; **ensure state is appropriate**.
5. Open PR and run fmt/validate; merge to main.
6. Read the generated Terraform plan in the Actions `plan` job logs. **Reject** if any existing `dev`/`sbox_sw` deletion/replacement appears.
7. Approve `aero-infra-apply` deployment to apply the *same* plan.

New PostgreSQL and Redis can incur significant recurring costs alongside `P3v3`. Check Azure SKU and quota availability in Central India before applying. PostgreSQL `zone=1` is a placement request, not automatic HA; Redis HA is independent.

## Layout

```text
.github/workflows/
  terraform-check.yml
  terraform-apply.yml
infra/terraform/
  terraform.tfvars  # non-secrets, QA-only, editing point
  locals.tf
  main.tf
  variables.tf
  outputs.tf
  versions.tf
  modules/
    environment/
    webapp/
    storage/
    postgres/
    redis/
scripts/
  bootstrap-state.sh
```

**Verification status:** Structural checks performed; Terraform CLI and Azure credentials were not available in the build runtime. `terraform validate` and a real provider `plan` must run in GitHub before approving `apply`.
