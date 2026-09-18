resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  # each.key is the map key. each.value is the object behind it.
  # With a map these are genuinely different, unlike the set case.
  bucket = "${var.project_name}-${each.key}"
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.buckets

  name              = "/aws/${var.project_name}/${each.key}"
  retention_in_days = each.value.retention_days
}

# Only some buckets get versioning. Filtering the map with a for expression
# means this resource exists only for the entries that asked for it, rather
# than existing for all of them with a disabled flag.
resource "aws_s3_bucket_versioning" "this" {
  for_each = { for k, v in var.buckets : k => v if v.versioned }

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}
