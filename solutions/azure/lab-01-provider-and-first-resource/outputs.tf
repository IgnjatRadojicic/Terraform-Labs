output "resource_group_name" {
  description = "The resource group everything else lives in."
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "The storage account, roughly the S3 bucket equivalent."
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Computed by Azure, not set by you. The closest thing to a bucket URL."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}
