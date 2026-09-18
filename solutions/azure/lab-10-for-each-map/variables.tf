variable "project_name" {
  description = "Short project identifier."
  type        = string
  default     = "platform"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

variable "containers" {
  description = "Containers to create, each with its own configuration."
  type = map(object({
    access_type    = string
    retention_days = number
    audited        = bool
  }))

  default = {
    uploads = {
      access_type    = "private"
      retention_days = 30
      audited        = true
    }
    reports = {
      access_type    = "private"
      retention_days = 90
      audited        = false
    }
    public-assets = {
      access_type    = "blob"
      retention_days = 365
      audited        = true
    }
  }
}
