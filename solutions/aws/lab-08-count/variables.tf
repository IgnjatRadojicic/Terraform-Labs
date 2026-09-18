variable "project_name" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "lakehouse"
}

variable "zones" {
  description = "Data zones to create a bucket for, in order."
  type        = list(string)
  default     = ["raw", "staging", "curated"]
}
