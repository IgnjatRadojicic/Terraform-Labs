variable "project_name" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "analytics"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Team responsible for these resources."
  type        = string
  default     = "data-platform"
}

variable "extra_tags" {
  description = "Additional tags merged on top of the common set."
  type        = map(string)
  default     = {}
}
