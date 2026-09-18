variable "project_name" {
  description = "Short project identifier, used to build resource names."
  type        = string
  default     = "coolngl"
}

variable "location" {
  description = "Azure region. Every Azure resource needs one, unlike S3."
  type        = string
  default     = "uksouth"
}

variable "retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}

variable "enable_versioning" {
  description = "Whether blob versioning is turned on."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "labs"
  }
}
