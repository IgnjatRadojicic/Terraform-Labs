locals {
  # Azure naming conventions are more rigid than AWS's, and Microsoft
  # publishes recommended prefixes: rg- for resource groups, st- for
  # storage accounts, log- for Log Analytics. Centralising them in locals
  # is worth more here than in the AWS track.
  #
  # Note the storage name strips hyphens, because storage accounts forbid
  # them while resource groups allow them. One convention cannot serve
  # both, and locals is where that gets reconciled once.
  name_prefix  = "${var.project_name}-${var.environment}"
  storage_name = lower(replace("st${var.project_name}${var.environment}", "-", ""))

  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = var.environment
    },
    var.extra_tags
  )
}
