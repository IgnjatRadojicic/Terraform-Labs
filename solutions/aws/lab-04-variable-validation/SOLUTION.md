# Solution: Lab 04, Variable validation blocks

## Approach

Four rules across three variables, chosen to cover the two patterns that handle almost every real case: `contains()` for a fixed set of allowed values, and `can(regex(...))` for a shape. `bucket_name` deliberately gets two separate blocks rather than one compound condition, so you can see what that buys.

## Walkthrough

### Why `can()` is not optional

```hcl
validation {
  condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
  error_message = "..."
}
```

`regex()` does not return `false` when there is no match. It **raises an error**. A condition that errors does not evaluate to false, it crashes the plan with a regex failure that says nothing about your rule.

`can()` wraps an expression and returns `true` or `false` depending on whether it errored. It converts a crash into the clean boolean a condition needs. This pairing is idiomatic enough that seeing `regex()` inside a validation without `can()` is a reliable smell.

### The anchors are the rule

```
^[a-z0-9][a-z0-9-]*[a-z0-9]$
```

Drop `^` and `$` and the pattern matches **anywhere inside** the string. `BAD-name-BAD` would pass, because `name` matches in the middle. You would have written a validation block that enforces nothing while looking correct in review.

The rest reads: start with a letter or digit, then any number of letters, digits or hyphens, then end with a letter or digit. That is how "cannot start or end with a hyphen" is expressed.

### Two blocks report two errors

```
$ terraform plan -var="bucket_name=AB"

Bucket name must be between 3 and 63 characters. Got 2.
Bucket name must be lowercase letters, digits and hyphens only, and cannot
start or end with a hyphen.
```

Both fired. Terraform evaluates every validation block and reports all failures together.

Written as one compound condition joined with `&&`, the user gets a single message that has to describe every rule at once, and they fix one problem only to discover the next on the following run. Separate blocks turn an iterative guessing game into one complete answer.

### Interpolating the bad value

```hcl
error_message = "Bucket name must be between 3 and 63 characters. Got ${length(var.bucket_name)}."
```

Error messages are expressions. Including the offending value costs nothing and saves the reader counting characters. Terraform also shows the value itself above the message:

```
  36: variable "retention_days" {
    ├────────────────
    │ var.retention_days is 45
```

### The uncomfortable part: the provider already does this

Comment out the retention validation and plan still fails:

```
Error: expected retention_in_days to be one of [0 1 3 5 7 14 30 60 90 120 150
180 365 400 545 731 1096 1827 2192 2557 2922 3288 3653], got 45
```

So your rule is **not** what stops the apply. Worth being honest about, because a lot of material implies otherwise.

Two things did change:

| | Provider's error | Your validation |
|---|---|---|
| Points at | the resource attribute | `variables.tf`, the variable |
| Names | `retention_in_days` | `retention_days`, the input the user actually set |
| Shows the value | no | yes, `var.retention_days is 45` |

The person who broke this set a **variable**, probably in a tfvars file, possibly without ever opening `main.tf`. An error naming the resource attribute makes them go hunting for the connection. An error naming their own input does not.

And the general case is stronger than this example. The provider validates what AWS accepts. It cannot validate what **your organisation** accepts. A rule saying production must use 365 days, or that bucket names must start with the team's prefix, has no provider equivalent. That is where validation blocks are the only tool.

### Validation runs before anything happens

Every one of these failures occurs during plan, before a single API call. Nothing is created, nothing is left half-built, and there is no cleanup. Compare that to a rule you enforce nowhere: the failure lands mid-apply, after some resources exist, and you are left reconciling partial infrastructure.

## Why not the alternative

**The tempting approach: one compound condition.**

```hcl
validation {
  condition = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
  error_message = "Invalid bucket name."
}
```

Fewer lines, and it rejects exactly the same inputs. It is still worse.

The error message can no longer be specific, because one message now covers three rules. `Invalid bucket name` sends the reader to the documentation. And the user fixes one violation at a time, learning about the next only on the next run.

The principle generalises past Terraform: **one assertion per check**, so the failure identifies itself. It is the same reason you do not write one test method that asserts eight things.

**A second tempting approach: skip validation because the provider catches it.**

For `retention_days` specifically, the provider does. But provider validation is silent about which of your inputs caused it, cannot express business rules, and is not guaranteed to exist for any given argument. Writing the rule where the value enters your configuration is the version that keeps working.

## Verification transcript

```
$ terraform validate
Success! The configuration is valid.

$ terraform apply -auto-approve
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ terraform state list
aws_cloudwatch_log_group.validated
aws_s3_bucket.validated
```

Every rule confirmed firing at plan time:

```
-var bucket_name=ab
    Bucket name must be between 3 and 63 characters. Got 2.

-var bucket_name=Has-Capitals
    Bucket name must be lowercase letters, digits and hyphens only, ...

-var environment=production
    Environment must be one of: dev, staging, prod.

-var retention_days=45
    Retention must be a value CloudWatch accepts. The common ones are
    30, 60, 90 and 365. Use 0 to retain forever.

-var bucket_name=AB
    validation errors reported: 2
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 8 covers validation. What shows up:

**`can()` versus `try()`.** `can()` returns a boolean, for conditions. `try()` returns the first non-erroring value from a list of alternatives, for defaults. A question offering `try()` inside a `validation` condition is offering the wrong tool.

**When validation runs.** Plan time, before the provider is consulted about resources. A question asking whether a bad variable reaches AWS is testing this.

**`error_message` is required.** A `validation` block without one will not parse.

Worth knowing, not covered here: since Terraform 1.9, a validation condition may reference **other variables**, not just its own. Before that it could only see `var.<its own name>`, which is why older code pushes cross-variable checks into `precondition` blocks instead. Those appear in Tier 3.
