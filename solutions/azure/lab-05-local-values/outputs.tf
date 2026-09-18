output "name_prefix" {
  description = "The shared prefix, computed once."
  value       = local.name_prefix
}

output "storage_name" {
  description = "Hyphens stripped, because storage accounts forbid them."
  value       = local.storage_name
}

output "common_tags" {
  description = "Defaults merged with caller-supplied tags."
  value       = local.common_tags
}
