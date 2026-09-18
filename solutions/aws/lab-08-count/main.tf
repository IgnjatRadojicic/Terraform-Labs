# count creates N copies of a resource, addressed by POSITION.
# The addresses are aws_s3_bucket.zone[0], [1], [2].
#
# That positional addressing is the whole lesson. It is fine while the list
# only ever grows at the end, and it is a trap the moment anything is
# removed from the middle.
resource "aws_s3_bucket" "zone" {
  count = length(var.zones)

  bucket = "${var.project_name}-${var.zones[count.index]}"
}

# count.index is also available for values that should differ per copy.
resource "aws_cloudwatch_log_group" "zone" {
  count = length(var.zones)

  name              = "/aws/${var.project_name}/${var.zones[count.index]}"
  retention_in_days = 7
}
