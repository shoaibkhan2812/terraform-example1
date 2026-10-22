variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "version" { type = string }
variable "sku_name" { type = string }
variable "availability_zone" { type = string }
variable "admin_username" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "storage_mb" { type = number }
variable "backup_retention_days" { type = number }
variable "public_network_access_enabled" { type = bool }
variable "firewall_rules" {
  type = map(object({ start_ip_address = string, end_ip_address = string }))
}
variable "tags" { type = map(string) }
