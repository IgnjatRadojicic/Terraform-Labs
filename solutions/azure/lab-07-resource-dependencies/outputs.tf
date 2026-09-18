output "container_name" {
  description = "The container, which depends on the storage account."
  value       = azurerm_storage_container.uploads.name
}

output "blob_url" {
  description = "Computed URL, proving the whole chain resolved in order."
  value       = azurerm_storage_blob.config.url
}

output "dependency_chain" {
  description = "The order Terraform must follow, top to bottom."
  value = join(" -> ", [
    azurerm_resource_group.main.name,
    azurerm_storage_account.main.name,
    azurerm_storage_container.uploads.name,
    azurerm_storage_blob.config.name,
  ])
}
