locals {
  # A computed naming prefix. Every resource derives its name from this, so
  # changing the convention is a one line edit rather than a find and replace.
  name_prefix = "${var.project_name}-${var.environment}"

  # The tag set every resource shares. Defined once, referenced everywhere.
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }

  # merge() combines maps, with later arguments winning on conflict. This
  # lets a caller override a common tag without editing this block.
  tags = merge(local.common_tags, var.extra_tags)
}
