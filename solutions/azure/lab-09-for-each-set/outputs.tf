output "container_names" {
  description = "A map of zone to container name, not a positional list."
  value       = { for k, c in azurerm_storage_container.zone : k => c.name }
}

output "curated_container" {
  description = "Addressed by KEY. Compare against Lab 08's [0]."
  value       = azurerm_storage_container.zone["curated"].name
}

output "instance_keys" {
  description = "The keys Terraform used to identify each instance."
  value       = sort(keys(azurerm_storage_container.zone))
}
