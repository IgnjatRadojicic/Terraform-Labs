# Solution: Lab 10, for_each over a map with varying configuration

## Approach

A `map(object(...))` where the key identifies the instance and the value carries its settings. Three buckets, three log groups with three different retentions, and a versioning resource that exists for only two of them because the map is filtered before it reaches `for_each`.

## Walkthrough

### Key and value now mean different things

```hcl
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.buckets

  name              = "/aws/${var.project_name}/${each.key}"
  retention_in_days = each.value.retention_days
}
```

With a set, `each.key` and `each.value` were the same. With a map they are not:

| | Holds |
|---|---|
| `each.key` | `"uploads"`, the map key, which becomes the resource address |
| `each.value` | `{ retention_days = 7, versioned = true }`, the object |

This is why a map is the general case and a set is the simple one. A set can only say *which* instances exist. A map says which instances exist **and** how each is configured.

### Filtering, not flagging

```hcl
resource "aws_s3_bucket_versioning" "this" {
  for_each = { for k, v in var.buckets : k => v if v.versioned }
  ...
}
```

The `for` expression produces a map containing only the entries where `versioned` is true. That map is still a valid `for_each` argument, so the resource simply has fewer instances.

The result: 3 buckets, 3 log groups, **2** versioning resources. If your apply reported 9 resources rather than 8, the filter did not filter.

### Indexing another for_each resource by the same key

```hcl
bucket = aws_s3_bucket.this[each.key].id
```

Because `aws_s3_bucket.this` is itself a map keyed by the same strings, `each.key` indexes straight into it. No string rebuilding, no second source of truth for the name.

Writing `bucket = "${var.project_name}-${each.key}"` here would produce the same string and be wrong for the reason from Lab 07: it creates no dependency, so Terraform could try to configure versioning on a bucket that does not exist yet.

### Independence under change

Because keys are stable, each entry is genuinely independent:

```
adding a 4th bucket        -> Plan: 2 to add, 0 to change, 0 to destroy
changing one retention     -> Plan: 0 to add, 1 to change, 0 to destroy
```

One changed value, one changed resource. Nothing else in the plan.

## Why not the alternative

**The tempting approach: create the versioning resource for everything and disable it where unwanted.**

```hcl
resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets                      # all of them

  versioning_configuration {
    status = each.value.versioned ? "Enabled" : "Suspended"
  }
}
```

This looks tidier, avoids the `for` expression, and produces infrastructure that is not the same.

`"Suspended"` is not the same as never having configured versioning. It is a real state with real semantics: a suspended bucket keeps existing versions but stops creating new ones. A bucket that was never versioned has no version machinery at all. If the distinction matters to you, the two configurations are not interchangeable.

Beyond S3, the general problems are:

| Problem | Effect |
|---|---|
| Three resources exist instead of two | State is larger, plans are noisier, every refresh makes an extra API call |
| Flipping the flag **modifies** rather than **destroys** | The plan says `1 to change` where you probably expected `1 to destroy` |
| Not every resource has a disabled state | The pattern does not generalise, so you learn a habit that fails elsewhere |

That middle row is the important one. Filtering means a resource stops existing. Flagging means it changes. Those produce different plans and different real-world outcomes, and you should pick deliberately rather than by which was easier to write.

**A second tempting approach: two separate variables, one map for buckets and one list of names to version.**

```hcl
variable "buckets" { ... }
variable "versioned_buckets" { type = list(string) }
```

Now nothing stops someone listing a bucket in `versioned_buckets` that does not exist in `buckets`. You have created a referential integrity problem that the single map made impossible. Keeping related configuration in one structure is a correctness property, not tidiness.

## Verification transcript

```
$ terraform apply -auto-approve
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

$ terraform state list
aws_cloudwatch_log_group.this["archive"]
aws_cloudwatch_log_group.this["reports"]
aws_cloudwatch_log_group.this["uploads"]
aws_s3_bucket.this["archive"]
aws_s3_bucket.this["reports"]
aws_s3_bucket.this["uploads"]
aws_s3_bucket_versioning.this["archive"]
aws_s3_bucket_versioning.this["uploads"]

$ terraform output
bucket_names = {
  "archive" = "platform-archive"
  "reports" = "platform-reports"
  "uploads" = "platform-uploads"
}
retention_by_bucket = {
  "archive" = 365
  "reports" = 90
  "uploads" = 7
}
versioned_buckets = [
  "archive",
  "uploads",
]
```

Eight resources, two versioning instances, three distinct retention values.

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

**`each.key` versus `each.value` with a map.** Asked directly. The key is the map key, the value is whatever the map holds at that key.

**Can `for_each` take a map of objects?** Yes. The restriction is on the collection type at the top level, a map or a set of strings, not on what the map contains.

**Filtering with a `for` expression inside `for_each`.** A question may show this and ask how many instances result. Count the entries surviving the `if`.

**Keys must be known at plan time.** A map whose keys come from a computed attribute produces an error. The workaround is to key off configuration, and questions about "Terraform cannot determine the full set of keys" are testing this.

Worth carrying into Tier 3: this map-of-objects shape is how nearly every published module accepts a collection of things, and combining it with `optional()` from Lab 12 is what makes such a module pleasant to call.
