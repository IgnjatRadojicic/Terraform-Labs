resource "aws_s3_bucket" "raw" {
  bucket = "${local.name_prefix}-raw"
  tags   = local.tags
}

resource "aws_s3_bucket" "processed" {
  bucket = "${local.name_prefix}-processed"
  tags   = local.tags
}

resource "aws_cloudwatch_log_group" "pipeline" {
  name              = "/aws/${local.name_prefix}/pipeline"
  retention_in_days = 30
  tags              = local.tags
}
