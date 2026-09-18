output "subscription_id" {
  description = "Read from the environment, not declared by you."
  value       = data.azurerm_client_config.current.subscription_id
}

output "tenant_id" {
  description = "Azure has a tenant above the subscription. AWS has no equivalent layer."
  value       = data.azurerm_client_config.current.tenant_id
}

output "object_id" {
  description = "The identity Terraform is authenticating as."
  value       = data.azurerm_client_config.current.object_id
}

output "created_resource_group" {
  description = "A resource, which Terraform owns and will destroy."
  value       = azurerm_resource_group.main.name
}
