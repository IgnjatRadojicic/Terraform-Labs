output "storage_account_name" {
  description = "The validated name."
  value       = azurerm_storage_account.main.name
}

output "location" {
  description = "The validated region."
  value       = azurerm_resource_group.main.location
}
