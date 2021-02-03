resource "random_string" "id" {
  count   = var.random_identifier == "" ? 1 : 0
  length  = 4
  upper   = false
  special = false
}

locals {
  random_id = var.random_identifier == "" ? random_string.id.0.result : var.random_identifier
}

module "luthername_sa_bucket" {
  source                = "../luthername"
  luther_project        = var.luther_project
  luther_env            = var.luther_env
  component             = var.component
  resource              = "sa"
  id                    = local.random_id
  delim                 = ""
}

resource "azurerm_storage_account" "bucket" {
  name                = module.luthername_sa_bucket.name
  resource_group_name = var.resource_group

  location = var.az_location

  account_tier             = "Premium"
  account_replication_type = "GZRS"

  enable_https_traffic_only = true

  tags = module.luthername_blob_bucket.tags
}

module "luthername_blob_bucket" {
  source                = "../luthername"
  luther_project        = var.luther_project
  luther_env            = var.luther_env
  component             = var.component
  resource              = "blob"
  id                    = local.random_id
}

resource "azurerm_storage_container" "bucket" {
  name                  = module.luthername_blob_bucket.name
  storage_account_name  = azurerm_storage_account.bucket.name
  container_access_type = "private"
}
