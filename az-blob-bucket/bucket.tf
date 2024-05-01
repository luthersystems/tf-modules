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
  source         = "../luthername"
  luther_project = var.luther_project
  luther_env     = var.luther_env
  component      = var.component
  resource       = "sa"
  id             = local.random_id
  delim          = ""
}

resource "azurerm_storage_account" "bucket" {
  name                = module.luthername_sa_bucket.name
  resource_group_name = var.resource_group

  location = var.az_location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "GRS"

  enable_https_traffic_only = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_delete_retention_days
    }
  }

  network_rules {
    default_action             = var.subnet_id != "" ? "Deny" : "Allow"
    ip_rules                   = [data.http.ip.response_body] # IMPORTANT: don't get locked out of storage APIs
    virtual_network_subnet_ids = var.subnet_id != "" ? [var.subnet_id] : null
    bypass                     = ["AzureServices"]
  }


  tags = module.luthername_blob_bucket.tags
}

module "luthername_blob_bucket" {
  source         = "../luthername"
  luther_project = var.luther_project
  luther_env     = var.luther_env
  component      = var.component
  resource       = "blob"
  id             = local.random_id
}

resource "azurerm_storage_container" "bucket" {
  name                  = module.luthername_blob_bucket.name
  storage_account_name  = azurerm_storage_account.bucket.name
  container_access_type = "private"
}

resource "azurerm_storage_encryption_scope" "bucket" {
  name               = "microsoftmanaged"
  storage_account_id = azurerm_storage_account.bucket.id
  source             = "Microsoft.Storage"
}

resource "azurerm_private_endpoint" "bucket" {
  count = var.subnet_id != "" ? 1 : 0

  name                = "${module.luthername_blob_bucket.name}-pe"
  location            = var.az_location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${module.luthername_blob_bucket.name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.bucket.id
    subresource_names              = ["blob"]
  }
}

data "http" "ip" {
  url = "https://ifconfig.me"
}
