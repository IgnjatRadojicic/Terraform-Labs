# Solution: Lab 03, Outputs and referencing resource attributes

## Approach

Four outputs chosen to make one distinction unmissable: two of them Terraform can resolve at plan time, two it cannot. The resources themselves are incidental.

## Walkthrough

### Arguments versus attributes

This is the idea the lab is built around, and it is worth being precise.

| | What it is | Where documented |
|---|---|---|
| **Argument** | A value you set on the resource | Argument Reference, top of the provider docs page |
| **Attribute** | A value you can read back | Attribute Reference, bottom of the same page |

Attributes are a superset. Everything you set is readable, plus everything AWS computed during creation. `bucket` is both, because you set it. `arn` is attribute-only, because AWS builds it.

That single fact explains the plan output:

```
+ bucket_name        = "reporting-data"
+ bucket_arn         = (known after apply)
```

`bucket_name` came from your own configuration, so Terraform already has it. `bucket_arn` does not exist yet, because the bucket does not exist yet.

### Unknown values propagate

`connection_summary` interpolates two values, one known and one not:

```hcl
value = "bucket ${aws_s3_bucket.data.bucket} logging to ${aws_cloudwatch_log_group.audit.name}"
```

Both happen to be known here, so the whole string resolves at plan time. Swap either for `.arn` and the entire output becomes `(known after apply)`. An expression containing one unknown is itself unknown, all the way up.

This matters beyond cosmetics. If a `count` or a `for_each` key depends on an unknown value, Terraform cannot build the resource graph at all and refuses to plan. That is the most common cause of the error telling you a value cannot be determined until apply.

### Outputs are expressions

An output is not a pointer at an attribute. It is an arbitrary expression:

```hcl
output "connection_summary" {
  value = "bucket ${aws_s3_bucket.data.bucket} logging to ${aws_cloudwatch_log_group.audit.name}"
}
```

That string exists nowhere in the configuration and in no resource. Outputs compute, which is what makes them useful as a module's public interface rather than a raw attribute dump.

### The CLI, and why `-raw` exists

```
$ terraform output bucket_arn
"arn:aws:s3:::reporting-data"

$ terraform output -raw bucket_arn
arn:aws:s3:::reporting-data
```

Plain `terraform output` renders values for a human, so strings carry quotes. `-raw` prints the bare string with no quotes and no trailing newline.

The difference is not cosmetic. This does the wrong thing:

```bash
aws s3 ls $(terraform output bucket_name)      # passes "reporting-data" WITH quotes
aws s3 ls $(terraform output -raw bucket_name) # passes reporting-data
```

`-raw` works only for a single string, number or boolean. For a list or map, use `-json` and parse it.

`terraform output -json` emits every output with its type and description, which is how CI pipelines and tools like Terragrunt consume a configuration.

### Outputs live in state

After `destroy`, `terraform output` reports there are no outputs. They are stored in the state file, not recomputed from configuration, which is how they survive between commands without a refresh. Delete the state and they are gone.

This also means **an output is not a secret boundary**. Marking one `sensitive` hides it from CLI display and nothing more. The value sits in plain text in the state file either way. That comes up again in Tier 3.

## Why not the alternative

**The tempting approach: skip outputs and read values from state when you need them.**

```bash
terraform state show aws_s3_bucket.data | grep arn
```

It works today, and it breaks as soon as anything depends on it.

`terraform state show` prints a human-readable rendering with no stability guarantee across Terraform versions. Grepping it is parsing an unversioned display format. More importantly, when this configuration becomes a module, **outputs are the only values a caller can see**. A parent module can read `module.reporting.bucket_arn`; it cannot reach into the child's state and grep.

Outputs are the module's public API. Everything else is an implementation detail. Deciding what to output is deciding what you are willing to support.

**A second tempting approach: output everything, just in case.**

Every output is a commitment. Remove one later and you break every caller referencing it. Outputs deserve the same restraint as a `public` member in C#, and for the same reason.

## Verification transcript

```
$ terraform apply -auto-approve
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::reporting-data"
bucket_name = "reporting-data"
connection_summary = "bucket reporting-data logging to /aws/reporting/audit"
log_group_arn = "arn:aws:logs:us-east-1:000000000000:log-group:/aws/reporting/audit"

$ terraform output -raw bucket_arn
arn:aws:s3:::reporting-data

$ terraform destroy -auto-approve
Destroy complete! Resources: 2 destroyed.
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 8 covers outputs. The reliable question types:

**What does `sensitive = true` actually do?** It redacts the value from CLI output. It does not encrypt it, does not remove it from state, and does not stop a parent module reading it. Answers claiming it secures the value are wrong.

**What does `-raw` do?** Prints a single value without quotes. A question may ask why a shell script is receiving quoted strings.

**Where do outputs live?** In state. That is why they survive between commands and why they vanish with the state file.

Worth knowing though this lab does not use it: an output can take `depends_on`, and it is one of the rare legitimate uses, for when a consumer needs something to be fully settled before reading the value.
