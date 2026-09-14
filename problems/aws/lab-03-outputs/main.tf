resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data"
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/${var.project_name}/audit"
  retention_in_days = 14
}
