resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-documents"
}

# IMPLICIT dependency. The reference to aws_s3_bucket.documents.id tells
# Terraform this cannot be created until the bucket exists. Nothing else
# is needed, and depends_on here would be redundant.
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# EXPLICIT dependency, and a genuine one rather than a contrived example.
#
# This object references the bucket, so Terraform already knows to create
# the bucket first. But it does NOT reference the versioning configuration,
# because it needs no data from it. Without depends_on, Terraform is free to
# write this object before versioning is switched on, and an object written
# to an unversioned bucket has no version history. The infrastructure would
# come out subtly wrong rather than failing loudly.
#
# This is the shape of a legitimate depends_on: a real ordering requirement
# with no data flowing between the two resources.
resource "aws_s3_object" "manifest" {
  bucket  = aws_s3_bucket.documents.id
  key     = "manifest.json"
  content = jsonencode({ project = var.project_name, schema = 1 })

  depends_on = [aws_s3_bucket_versioning.documents]
}
