# Solution: Lab 02, Input variables with types and defaults

## Approach

Four variables, one per primitive type the exam cares about, each wired into a resource argument where that type is the natural fit. `project_name` deliberately has no default so you experience a required variable. The other three have defaults so the configuration runs standalone.

The interesting part of this lab is not the declarations. It is steps 5 through 7, where the observable behaviour contradicts what most people assume.

## Walkthrough

### The declarations

```hcl
variable "project_name" {
  description = "Name prefix applied to every resource in this configuration."
  type        = string
}

variable "retention_days" {
  description = "Days CloudWatch keeps log events before deleting them."
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
```

Three decisions worth naming:

**No default on `project_name` makes it required.** There is no `required = true` argument. The absence of `default` is the mechanism. Terraform prompts interactively, or fails under `-input=false`:

```
Error: No value for required variable

  on variables.tf line 1:
   1: variable "project_name" {

The root module input variable "project_name" is not set, and has no default value.
```

**`force_destroy` defaults to `false`, not `true`.** The value that makes your life easier during practice is the destructive one. Defaulting to it is how someone eventually loses a bucket they meant to keep. Defaults should be the safe choice, and the convenient choice should be explicit.

**`description` is not decoration.** It appears in `terraform plan` prompts and in generated documentation. In a shared repository it is the only place the intent of a variable is recorded.

### Precedence, which is genuinely counter-intuitive

Verified empirically rather than quoted from memory:

| Source | Value that won |
|---|---|
| `terraform.tfvars` alone | `acme-portal` |
| `TF_VAR_project_name=from-env` plus `terraform.tfvars` | `acme-portal` |
| `-var="project_name=from-cli"` plus `terraform.tfvars` | `from-cli` |
| `zz.auto.tfvars` plus `terraform.tfvars` | `from-auto` |

So, lowest priority to highest:

1. Environment variables (`TF_VAR_name`)
2. `terraform.tfvars` and `terraform.tfvars.json`
3. `*.auto.tfvars`, in lexical filename order
4. `-var` and `-var-file` on the command line, last one wins

**Environment variables are the weakest source.** This catches people out, because in most tools an explicitly exported environment variable overrides a config file. Here it is the opposite. A `terraform.tfvars` committed to the repository silently beats the `TF_VAR_` you just exported, and nothing warns you.

### Undeclared variables warn, they do not error

Adding `nonexistent_variable = "oops"` to `terraform.tfvars` produces:

```
Warning: Value for undeclared variable

The root module does not declare a variable named "nonexistent_variable"
but a value was found in file "terraform.tfvars".
```

A warning. The plan proceeds.

This matters more than it looks. Typo `retention_days` as `retention_day` in your tfvars and Terraform does not stop. It warns, ignores your value, and silently uses the default of 30 instead of your intended 90. In a wall of plan output, a warning is easy to miss, and the resulting configuration is wrong in a way that looks fine.

Treat these warnings as errors. `-compact-warnings` makes them easier to spot rather than easier to ignore.

### Type conversion, and where it stops working

Step 7 asked you to predict what `retention_days = "90"` does in a tfvars file. It works. Terraform converts the string to a number, because the conversion is unambiguous.

But the same value passed on the command line fails. Verified matrix:

| How the value was supplied | Result |
|---|---|
| tfvars: `retention_days = "90"` | Converted to `90` |
| tfvars: `force_destroy = "true"` | Converted to `true` |
| CLI: `-var=retention_days=90` | Works |
| CLI: `-var='retention_days="90"'` | **Error:** a number is required |
| CLI: `-var='force_destroy="true"'` | **Error:** bool is required |

The practical lesson is about shell quoting. When scripting Terraform in CI, quotes you add for the shell's benefit can end up inside the value and change its type. If a `-var` fails with a type error on a value that looks obviously correct, count your quotes.

## Why not the alternative

**The tempting approach: give `project_name` a default like `"my-project"` so nothing ever prompts you.**

It removes a small friction now and creates a large one later. A required variable is a forcing function. Someone deploying this configuration must consciously decide what to call their project. With a default, the failure mode is a real deployment quietly named `my-project`, and nobody notices until two environments collide on the same bucket name.

The rule worth internalising: **default anything that has a sane universal value, require anything that identifies this particular deployment.** Retention days has a sane default. A project name does not.

**A second tempting approach: type everything as `string` and convert later.**

`type = string` on `retention_days` would accept `"ninety"` without complaint and fail at apply time, after some resources have already been created, with an error from the AWS API rather than from Terraform. Declaring `number` moves that failure to plan time, before anything exists. Types are the cheapest validation available, and they cost one word.

## Verification transcript

```
$ terraform validate
Success! The configuration is valid.

$ terraform apply -auto-approve
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

$ terraform state list
aws_cloudwatch_log_group.app
aws_s3_bucket.uploads
aws_s3_bucket_cors_configuration.uploads
```

Confirming the variable values actually reached AWS, not just the plan:

```
$ aws --endpoint-url=http://localhost:4566 s3 ls
2026-09-11 20:31:04 acme-portal-uploads

$ aws --endpoint-url=http://localhost:4566 logs describe-log-groups \
    --query 'logGroups[].[logGroupName,retentionInDays]' --output text
/aws/acme-portal/application    90

$ aws --endpoint-url=http://localhost:4566 s3api get-bucket-cors --bucket acme-portal-uploads
{
  "CORSRules": [
    {
      "AllowedMethods": ["GET", "PUT"],
      "AllowedOrigins": [
        "https://admin.acme.example",
        "https://app.acme.example"
      ]
    }
  ]
}
```

Required variable behaviour with no tfvars present:

```
$ terraform plan -input=false
Error: No value for required variable
```

Teardown:

```
$ terraform destroy -auto-approve
Destroy complete! Resources: 3 destroyed.
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0. Apply takes about 8 seconds.

### One emulator quirk

LocalStack returned the CORS origins in a different order than they were declared, `admin` before `app`. A `list(string)` is ordered, and real S3 preserves the order you send. This is LocalStack normalising, not Terraform reordering your list.

It is a good illustration of a rule from `SETUP-AWS.md`: never write a check that depends on the exact shape of emulator output. Verify that both origins are present, not that they appear in a specific order.

## Exam connection

Objective 8 covers variables and is one of the largest sections. Expect questions on all of this.

The three traps most likely to appear:

**Precedence order.** A question gives you a `terraform.tfvars`, an exported `TF_VAR_`, and a `-var` flag, then asks which wins. The answer is `-var`, and the distractor is the environment variable, which is actually the weakest.

**Required variables.** There is no `required` argument. Omitting `default` is the mechanism. A question offering `required = true` as an option is offering you something that does not exist.

**Undeclared variables.** Warning, not error. A question asking what happens when a tfvars file contains a key with no matching `variable` block is testing whether you know Terraform continues.

Worth knowing although this lab does not cover it: `*.auto.tfvars` files load automatically, but a file named anything else, such as `prod.tfvars`, requires `-var-file=prod.tfvars` explicitly. The `terraform.tfvars` name and the `.auto.tfvars` suffix are the only two that load on their own.
