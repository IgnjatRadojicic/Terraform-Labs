output "container_names" {
  description = "Map of key to created container name."
  value       = { for k, c in azurerm_storage_container.this : k => c.name }
}

output "access_types" {
  description = "Each instance received its own configuration."
  value       = { for k, c in azurerm_storage_container.this : k => c.container_access_type }
}

output "retention_by_container" {
  description = "Three different retentions from one resource block."
  value       = { for k, w in azurerm_log_analytics_workspace.this : k => w.retention_in_days }
}

output "audited_containers" {
  description = "Only the filtered entries got an audit container."
  value       = sort(keys(azurerm_storage_container.audit))
}
