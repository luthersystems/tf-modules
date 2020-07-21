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

provider "azurerm" {
  version = "~> 2.19.0"
  features {}
}

provider "random" {}
