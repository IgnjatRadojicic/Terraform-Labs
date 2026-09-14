output "name_prefix" {
  description = "The computed prefix every resource name is built from."
  value       = local.name_prefix
}

output "applied_tags" {
  description = "The final tag set after merging."
  value       = local.tags
}
