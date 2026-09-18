variable "project_name" {
  description = "Short project identifier."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

variable "extra_tags" {
  description = "Caller-supplied tags, layered over the defaults."
  type        = map(string)
  default     = {}
}
