# Azure's storage account naming rules are far stricter than S3's, which
# makes them a better validation exercise than the AWS equivalent.
#
#   3 to 24 characters
#   lowercase letters and digits only
#   no hyphens, no underscores, no uppercase
#   globally unique across every Azure subscription in the world
#
# Get this wrong and the failure arrives at APPLY, from the Azure API,
# after the resource group already exists. A validation block moves it to
# plan, before anything is created.
variable "storage_account_name" {
  description = "Globally unique storage account name."
  type        = string
  default     = "stlabsvalidation01"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Storage account names must be 3 to 24 characters. Got ${length(var.storage_account_name)}."
  }

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account names allow only lowercase letters and digits. No hyphens, underscores or capitals."
  }
}

variable "location" {
  description = "Azure region, restricted to ones this team uses."
  type        = string
  default     = "uksouth"

  validation {
    condition     = contains(["uksouth", "ukwest", "westeurope", "northeurope"], var.location)
    error_message = "Location must be one of: uksouth, ukwest, westeurope, northeurope."
  }
}

variable "replication_type" {
  description = "Storage redundancy."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS"], var.replication_type)
    error_message = "Replication must be one of: LRS, ZRS, GRS, RAGRS."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test or prod."
  }
}
