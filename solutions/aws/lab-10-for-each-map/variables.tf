variable "project_name" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "platform"
}

# A map of objects. The KEY becomes the resource address. The VALUE carries
# the per-instance configuration, which is what a set could never do.
variable "buckets" {
  description = "Buckets to create, keyed by short name."
  type = map(object({
    retention_days = number
    versioned      = bool
  }))

  default = {
    uploads = {
      retention_days = 7
      versioned      = true
    }
    reports = {
      retention_days = 90
      versioned      = false
    }
    archive = {
      retention_days = 365
      versioned      = true
    }
  }
}
