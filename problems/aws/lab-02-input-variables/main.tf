resource "aws_s3_bucket" "uploads" {
  bucket        = "${var.project_name}-uploads"
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_methods = ["GET", "PUT"]
    allowed_origins = var.allowed_origins
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/${var.project_name}/application"
  retention_in_days = var.retention_days
}
