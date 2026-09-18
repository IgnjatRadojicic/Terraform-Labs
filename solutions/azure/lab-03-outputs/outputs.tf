# An ARGUMENT is something you set. You already know it, so outputting it
# is usually pointless.
output "storage_account_name" {
  description = "An argument. Known before apply."
  value       = azurerm_storage_account.data.name
}

# An ATTRIBUTE is something Azure computes. This is what outputs are for.
# Azure resource IDs are full ARM paths, which is very different from an
# AWS ARN and matters enormously when you reach imports.
output "storage_account_id" {
  description = "Computed by Azure. A full ARM resource path, not a short ID."
  value       = azurerm_storage_account.data.id
}

output "primary_blob_endpoint" {
  description = "Computed URL. Shows as (known after apply) in the plan."
  value       = azurerm_storage_account.data.primary_blob_endpoint
}

output "workspace_id" {
  description = "The workspace GUID, distinct from its ARM resource ID."
  value       = azurerm_log_analytics_workspace.audit.workspace_id
}

# Some Azure attributes are secrets and the provider marks them sensitive
# automatically. Terraform refuses to print this unless you say so, which
# is a protection AWS's S3 resources rarely trigger.
output "primary_access_key" {
  description = "Marked sensitive BY THE PROVIDER, not by you."
  value       = azurerm_storage_account.data.primary_access_key
  sensitive   = true
}
