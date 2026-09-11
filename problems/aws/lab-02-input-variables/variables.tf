// Declare all four variables here.
//
// main.tf already references every one of them, so until this file is
// complete `terraform validate` will fail telling you the variables are
// not declared. That is expected.
//
// Reminder on the shape of a declaration:
//
//   variable "name" {
//     description = "..."
//     type        = ...
//     default     = ...   // omitting this makes the variable required
//   }

// TODO 1: project_name
//   Name prefix applied to every resource. Used to build the bucket name
//   and the log group path.
//   Type: text.
//   Default: none. This one is required.

// TODO 2: retention_days
//   How many days CloudWatch keeps log events before deleting them.
//   Type: numeric.
//   Default: 30.

// TODO 3: force_destroy
//   Whether Terraform may delete the bucket while objects remain inside
//   it. Without this, destroying a non-empty bucket fails.
//   Type: true or false.
//   Default: false. Defaulting to the destructive option is a bad habit.

// TODO 4: allowed_origins
//   Origins permitted to make cross-origin browser requests against the
//   bucket. There can be several, and order is meaningful to no one but
//   the list still has an order.
//   Type: a collection of text values.
//   Default: ["https://localhost:3000"]
