terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

}

# Define Azure authentication variables
variable "AZURE_SUBSCRIPTION_ID" {}
variable "AZURE_CLIENT_ID" {}
variable "AZURE_CLIENT_SECRET" {}
variable "AZURE_TENANT_ID" {}

provider "azurerm" {
  features {}

  # Optional: specify a specific Azure Environment - if not set, the public Azure Environment is used
  environment = "public"

  # Service Principal Authentication
  subscription_id = var.AZURE_SUBSCRIPTION_ID
  client_id       = var.AZURE_CLIENT_ID
  client_secret   = var.AZURE_CLIENT_SECRET
  tenant_id       = var.AZURE_TENANT_ID
}


