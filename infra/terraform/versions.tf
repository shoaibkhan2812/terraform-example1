terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Fixed version makes saved-plan apply consistent across GitHub jobs.
      version = "= 5.7.0"
    }
  }
  # GitHub Actions passes existing state storage details to terraform init.
  backend "azurerm" {}
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
