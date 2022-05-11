terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.59.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

module "aws_az_bucket_static" {
  source         = "../../"
  luther_project = "project"
  az_location    = "uksouth"
  resource_group = "luthertflnprodrg0"
  luther_env     = "env"
  component      = "static"

  providers = {
    azurerm = azurerm
    random  = random
  }
}
