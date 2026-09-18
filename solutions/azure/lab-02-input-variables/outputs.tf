output "storage_account_name" {
  description = "Name built from the project variable."
  value       = azurerm_storage_account.uploads.name
}

output "retention_days" {
  description = "Resolved retention, showing tfvars beating the default."
  value       = azurerm_log_analytics_workspace.main.retention_in_days
}
