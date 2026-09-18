variable "project_name" {
  description = "Short project identifier."
  type        = string
  default     = "lakehouse"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "uksouth"
}

variable "zones" {
  description = "Data zones. One container and one workspace per zone."
  type        = list(string)
  default     = ["raw", "staging", "curated"]
}
