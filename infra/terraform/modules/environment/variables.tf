variable "project_code" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "linux_plan_needed" { type = bool }
variable "windows_plan_needed" { type = bool }
variable "linux_plan_sku" { type = string }
variable "windows_plan_sku" { type = string }
variable "tags" { type = map(string) }
