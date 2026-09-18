variable "project_name" {
  description = "Name prefix applied to every resource."
  type        = string
  default     = "lakehouse"
}

# Deliberately a list, not a set. for_each will not accept this directly,
# and converting it is the point of the lab.
variable "zones" {
  description = "Data zones to create a bucket for."
  type        = list(string)
  default     = ["raw", "staging", "curated"]
}
