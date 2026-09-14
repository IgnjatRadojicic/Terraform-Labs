# A RESOURCE. Terraform creates this, owns it, records it in state, and will
# destroy it on terraform destroy.
resource "aws_s3_bucket" "managed" {
  bucket = "${var.project_name}-managed"
}

# A DATA SOURCE reading the bucket above. It creates nothing. It reads, on
# every plan, and it is not destroyed.
#
# The reference to aws_s3_bucket.managed.bucket is what forces this to be
# read AFTER the bucket exists. Without that reference Terraform would try
# to read a bucket that has not been created yet.
data "aws_s3_bucket" "lookup" {
  bucket = aws_s3_bucket.managed.bucket
}

# Data sources that describe the caller rather than a resource. These are
# the two most commonly used in real configurations, because they let a
# module work out where it is running without being told.
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Using a value that came from the data source rather than the resource.
# Functionally identical here, which is itself the lesson.
resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/${data.aws_s3_bucket.lookup.id}/audit"
  retention_in_days = 7
}
