# A count-created resource is a LIST. Referencing it without an index gives
# you the whole list, and the splat operator pulls one attribute from each.
output "bucket_names" {
  description = "All bucket names, in list order."
  value       = aws_s3_bucket.zone[*].bucket
}

output "first_bucket" {
  description = "Addressed by position, which is the only way count allows."
  value       = aws_s3_bucket.zone[0].bucket
}

output "bucket_count" {
  description = "How many were created."
  value       = length(aws_s3_bucket.zone)
}
