# for_each addresses instances by KEY rather than by position.
# The addresses here are aws_s3_bucket.zone["raw"], ["staging"], ["curated"].
#
# toset() is required. for_each accepts a set or a map, never a list,
# because a list has an order and order is exactly what for_each refuses
# to depend on.
resource "aws_s3_bucket" "zone" {
  for_each = toset(var.zones)

  # With a set, each.key and each.value are identical. That surprises
  # people, and it is why a set of strings is the simplest for_each case.
  bucket = "${var.project_name}-${each.key}"
}

resource "aws_cloudwatch_log_group" "zone" {
  for_each = toset(var.zones)

  name              = "/aws/${var.project_name}/${each.value}"
  retention_in_days = 7
}
