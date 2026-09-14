output "resource_bucket_arn" {
  description = "ARN as reported by the resource Terraform manages."
  value       = aws_s3_bucket.managed.arn
}

output "data_source_bucket_arn" {
  description = "ARN as reported by the data source reading that same bucket."
  value       = data.aws_s3_bucket.lookup.arn
}

output "region" {
  description = "Region the provider is configured for, discovered at runtime."
  value       = data.aws_region.current.region
}

output "account_id" {
  description = "Account ID the credentials belong to."
  value       = data.aws_caller_identity.current.account_id
}
