output "storage_account" {
  value = azurerm_storage_account.bucket.name
}

output "storage_account_id" {
  value = azurerm_storage_account.bucket.id
}

output "storage_container" {
  value = azurerm_storage_container.bucket.name
}

output "storage_container_id" {
  value = azurerm_storage_container.bucket.id
}

output "storage_account_primary_access_key" {
  value     = azurerm_storage_account.bucket.primary_access_key
  sensitive = true
}
