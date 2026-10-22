variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "service_plan_id" { type = string }
variable "acr_id" { type = string }
variable "acr_login_server" { type = string }
variable "image" { type = string }
variable "port" { type = number }
variable "allowed_origins" { type = list(string) }
variable "tags" { type = map(string) }
variable "container_os" {
  type = string
  validation {
    condition     = contains(["Linux", "Windows"], var.container_os)
    error_message = "container_os must be Linux or Windows."
  }
}
