# A for_each resource is a MAP, keyed by the set values. There is no [0].
output "bucket_names" {
  description = "Map of zone name to bucket name."
  value       = { for k, b in aws_s3_bucket.zone : k => b.bucket }
}

output "curated_bucket" {
  description = "Addressed by key, which is stable regardless of what else changes."
  value       = aws_s3_bucket.zone["curated"].bucket
}

output "instance_keys" {
  description = "The keys Terraform used as resource addresses."
  value       = sort(keys(aws_s3_bucket.zone))
}
