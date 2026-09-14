# An output you wrote the value of yourself. Terraform knows this at plan
# time, so it appears in plan output rather than as (known after apply).
output "bucket_name" {
  description = "Name of the bucket holding report data."
  value       = aws_s3_bucket.data.bucket
}

# An attribute AWS assigns during creation. Terraform cannot know it until
# apply has happened, which is why plan shows (known after apply).
output "bucket_arn" {
  description = "ARN of the data bucket, for use in IAM policies."
  value       = aws_s3_bucket.data.arn
}

output "log_group_arn" {
  description = "ARN of the audit log group."
  value       = aws_cloudwatch_log_group.audit.arn
}

# Outputs are expressions, not just passthroughs. This one composes a value
# that exists nowhere in the configuration.
output "connection_summary" {
  description = "Human readable summary of what was created."
  value       = "bucket ${aws_s3_bucket.data.bucket} logging to ${aws_cloudwatch_log_group.audit.name}"
}
