# The splat operator pulls one attribute from every instance at once.
output "container_names" {
  description = "Every container name, as a list."
  value       = azurerm_storage_container.zone[*].name
}

output "first_container" {
  description = "Addressed by POSITION, which is the whole problem with count."
  value       = azurerm_storage_container.zone[0].name
}

output "container_count" {
  description = "How many were created."
  value       = length(azurerm_storage_container.zone)
}
