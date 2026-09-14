// Add validation rules to these three variables.
//
// A validation block lives INSIDE a variable block:
//
//   variable "example" {
//     type = string
//
//     validation {
//       condition     = <expression that must evaluate to true>
//       error_message = "Shown to the user when condition is false."
//     }
//   }
//
// A variable may have more than one validation block. Prefer several
// focused rules over one compound condition joined with &&, so that a
// failure tells the user exactly which rule they broke.

variable "bucket_name" {
  description = "Name of the bucket. Must satisfy the real S3 naming rules."
  type        = string

  // TODO 1: length between 3 and 63 characters.
  //   Include the offending length in the error message, so the user does
  //   not have to count characters themselves.

  // TODO 2: lowercase letters, digits and hyphens only, and it may not
  //   start or end with a hyphen.
  //
  //   You will need a regular expression. Note that the regex function
  //   raises an error when there is no match rather than returning false,
  //   so on its own it crashes instead of failing validation cleanly.
  //   There is another function whose entire job is to fix that.
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  // TODO 3: must be one of dev, staging or prod.
}

variable "retention_days" {
  description = "Log retention. AWS only accepts specific values, not any integer."
  type        = number
  default     = 30

  // TODO 4: must be one of the values CloudWatch actually accepts:
  //   0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731,
  //   1096, 1827, 2192, 2557, 2922, 3288, 3653
  //   (0 means retain forever)
  //
  //   Fair warning, because it changes what this rule is for: the AWS
  //   provider already rejects a bad retention value on its own. Your
  //   rule is not what stops the apply.
  //
  //   Write it anyway, then step 6 of the problem statement has you
  //   remove it and compare the two error messages. What differs is
  //   where the error points and whether the reader can act on it,
  //   which turns out to be most of the value of a validation block.
}
