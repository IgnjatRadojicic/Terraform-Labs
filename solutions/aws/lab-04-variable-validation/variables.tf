variable "bucket_name" {
  description = "Name of the bucket. Must satisfy the real S3 naming rules."
  type        = string

  # Two separate validation blocks rather than one compound condition.
  # Each reports its own message, and Terraform reports ALL failing rules
  # at once, so a user who breaks both is told about both.
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters. Got ${length(var.bucket_name)}."
  }

  validation {
    # can() turns an error into false. regex() raises when there is no
    # match, so without can() a non-matching name crashes the plan
    # instead of failing this validation cleanly.
    #
    # The ^ and $ anchors matter. Without them the pattern matches
    # anywhere inside the string, and "BAD-name-BAD" would pass.
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase letters, digits and hyphens only, and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "retention_days" {
  description = "Log retention. CloudWatch accepts only specific values, not any integer."
  type        = number
  default     = 30

  # This list matches what the AWS provider itself accepts. The provider
  # would reject a bad value anyway, so this rule is not what stops the
  # apply. What it changes is where the error points and what it says.
  validation {
    condition = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
    365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.retention_days)
    error_message = "Retention must be a value CloudWatch accepts. The common ones are 30, 60, 90 and 365. Use 0 to retain forever."
  }
}
