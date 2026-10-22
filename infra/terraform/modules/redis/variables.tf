variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku_name" { type = string }
variable "high_availability_enabled" { type = bool }
variable "public_network_access" { type = string }
variable "access_keys_authentication" { type = bool }
variable "tags" { type = map(string) }
