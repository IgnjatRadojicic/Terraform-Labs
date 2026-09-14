// Build four things here. Three of them create nothing.

// TODO 1: a RESOURCE, aws_s3_bucket named "managed"
//   bucket = the project_name variable followed by "-managed"
//
//   Terraform creates this, owns it, records it in state, and destroys it
//   on terraform destroy.

// TODO 2: a DATA SOURCE, data "aws_s3_bucket" named "lookup"
//   Point it at the bucket you just declared, by REFERENCE not by
//   repeating the name as a string.
//
//   A data source creates nothing. It reads, on every plan.
//
//   Think about why the reference matters here beyond tidiness. If you
//   hardcoded the name instead, what would Terraform try to do on the
//   very first apply, when the bucket does not exist yet?

// TODO 3: two data sources that describe the caller rather than a resource
//   data "aws_region" named "current"
//   data "aws_caller_identity" named "current"
//
//   Both take no arguments at all. Their bodies are empty.
//   These are how a module works out where it is running without being
//   told, which is why they appear in almost every real configuration.

// TODO 4: a RESOURCE, aws_cloudwatch_log_group named "audit"
//   name              = "/aws/" then the bucket id AS REPORTED BY THE
//                       DATA SOURCE, then "/audit"
//   retention_in_days = 7
//
//   Using the data source here rather than the resource is deliberate.
//   The result is identical, and that is the point worth noticing.
