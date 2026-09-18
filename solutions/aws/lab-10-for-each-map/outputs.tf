output "bucket_names" {
  description = "Map of short name to real bucket name."
  value       = { for k, b in aws_s3_bucket.this : k => b.bucket }
}

output "versioned_buckets" {
  description = "Only the buckets that actually got a versioning resource."
  value       = sort(keys(aws_s3_bucket_versioning.this))
}

output "retention_by_bucket" {
  description = "Proof that each instance got its own configuration."
  value       = { for k, g in aws_cloudwatch_log_group.this : k => g.retention_in_days }
}
