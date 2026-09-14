resource "aws_s3_bucket" "validated" {
  bucket = var.bucket_name
}

resource "aws_cloudwatch_log_group" "validated" {
  name              = "/aws/${var.bucket_name}/${var.environment}"
  retention_in_days = var.retention_days
}
