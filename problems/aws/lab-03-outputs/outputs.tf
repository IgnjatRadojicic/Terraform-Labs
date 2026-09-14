// Declare four outputs here. main.tf is complete, do not edit it.
//
//   variable  = a value going INTO your configuration
//   output    = a value coming OUT of it
//
// Shape of an output block:
//
//   output "name" {
//     description = "..."
//     value       = <expression>
//   }

// TODO 1: bucket_name
//   The name of the bucket. You wrote this value yourself, so Terraform
//   already knows it before anything is created. Watch how plan displays
//   it compared to the next one.

// TODO 2: bucket_arn
//   The bucket's ARN. AWS assigns this during creation, so Terraform
//   cannot know it until apply has run.

// TODO 3: log_group_arn
//   The audit log group's ARN.

// TODO 4: connection_summary
//   A single sentence combining the bucket name and the log group name,
//   for example:
//
//     bucket reporting-data logging to /aws/reporting/audit
//
//   Outputs are expressions, not just pointers at an attribute. Build
//   this from the two resources, not from var.project_name.
