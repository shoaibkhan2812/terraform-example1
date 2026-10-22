variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Azure Storage account name must be 3-24 lowercase letters or numbers."
  }
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "account_tier" { type = string }
variable "account_replication_type" { type = string }
variable "tags" { type = map(string) }
