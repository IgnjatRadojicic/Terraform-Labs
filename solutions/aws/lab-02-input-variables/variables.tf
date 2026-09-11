variable "project_name" {
  description = "Name prefix applied to every resource in this configuration."
  type        = string
}

variable "retention_days" {
  description = "Days CloudWatch keeps log events before deleting them. Must be a value AWS accepts."
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket even when objects remain in it."
  type        = bool
  default     = false
}

variable "allowed_origins" {
  description = "Origins permitted to make cross-origin requests against the bucket."
  type        = list(string)
  default     = ["https://localhost:3000"]
}
