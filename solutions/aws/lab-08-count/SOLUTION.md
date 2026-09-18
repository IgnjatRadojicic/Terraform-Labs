# Solution: Lab 08, count for near-identical resources

## Approach

Six resources from two blocks, driven by `length(var.zones)` and indexed with `count.index`. The configuration is four lines long. The lab is not really about writing it, it is about the plan you get in step 7.

## Walkthrough

### The mechanics

```hcl
resource "aws_s3_bucket" "zone" {
  count  = length(var.zones)
  bucket = "${var.project_name}-${var.zones[count.index]}"
}
```

`count` takes a number. `count.index` is the current iteration, starting at 0. Indexing the list with it gives each instance its zone.

Terraform creates instances at addresses `aws_s3_bucket.zone[0]`, `[1]`, `[2]`.

### The splat operator

```hcl
output "bucket_names" {
  value = aws_s3_bucket.zone[*].bucket
}
```

`[*]` pulls one attribute from every instance and returns a list. It is equivalent to `[for b in aws_s3_bucket.zone : b.bucket]` but shorter, and it is what the exam asks about.

A `count` resource referenced without an index is a **list**. That is why `length()` works on it directly and why `[0]` is the only way to reach a single instance.

### The failure, in detail

This is the lab.

Appending a zone is fine:

```
$ terraform plan -var='zones=["raw","staging","curated","archive"]'
Plan: 2 to add, 0 to change, 0 to destroy.
```

Removing one from the middle is not:

```
$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone[1] must be replaced
  # aws_s3_bucket.zone[2] will be destroyed
Plan: 2 to add, 0 to change, 4 to destroy.
```

**One zone removed. Four resources destroyed, two recreated.**

Here is why. State holds identity by position:

| Address | Before | After |
|---|---|---|
| `zone[0]` | raw | raw |
| `zone[1]` | staging | **curated** |
| `zone[2]` | curated | does not exist |

Terraform compares `zone[1]` against `zone[1]`. It previously held a bucket named `lakehouse-staging`, and now the configuration says `zone[1]` should be named `lakehouse-curated`.

A bucket name cannot be changed in place. It is the resource's identity to S3. So Terraform must destroy and recreate it. `zone[2]` no longer appears in the configuration at all, so it is destroyed outright.

The sting: **`lakehouse-curated` was deleted and recreated, and you never touched it.** On a bucket holding data, or a database, that is an outage caused by editing a different line.

Appending is safe only because appending does not shift any existing index.

## Why not the alternative

**The tempting approach: keep using count and just be careful to only append.**

This is what people actually do, and it works right up until it does not. The problems are social rather than technical:

- The constraint is invisible. Nothing in the configuration says "never remove from the middle", so the next person reorders the list alphabetically because it looked untidy.
- Real inputs are not always yours to order. The moment `zones` comes from a data source, another module's output, or a `for` expression over something else, you no longer control the ordering.
- The failure is discovered at plan time, but only if someone reads the plan. `terraform apply -auto-approve` in a pipeline does not read it.

The honest summary is that `count` over a list of distinct things is a latent bug with a delay fuse. Lab 09 removes the fuse.

**A second tempting approach: `count` with a sorted list, so ordering is deterministic.**

```hcl
count = length(sort(var.zones))
```

This makes ordering stable but does not fix the problem. Sorting `["raw","staging","curated"]` gives `["curated","raw","staging"]`, and removing `raw` still shifts `staging` down. Deterministic index assignment is not the same as stable index assignment, and only the second one matters.

### Where count is still correct

Not everywhere is a trap. `count` remains the right tool when:

| Case | Why |
|---|---|
| `count = var.enabled ? 1 : 0` | A resource that exists zero or one times. Lab 16 |
| N genuinely interchangeable copies | Where no instance has an identity worth naming |
| Indexing a positional list you control end to end | Availability zones, occasionally |

The test to apply: **does each instance have a natural name?** If yes, use `for_each`. If the instances are genuinely anonymous and interchangeable, `count` is fine.

## Verification transcript

```
$ terraform apply -auto-approve
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

$ terraform state list
aws_cloudwatch_log_group.zone[0]
aws_cloudwatch_log_group.zone[1]
aws_cloudwatch_log_group.zone[2]
aws_s3_bucket.zone[0]
aws_s3_bucket.zone[1]
aws_s3_bucket.zone[2]

$ terraform plan -var='zones=["raw","staging","curated","archive"]'
Plan: 2 to add, 0 to change, 0 to destroy.

$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone[1] must be replaced
  # aws_s3_bucket.zone[2] will be destroyed
Plan: 2 to add, 0 to change, 4 to destroy.
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

Objective 8 covers `count` and `for_each`, and the comparison between them is one of the most commonly tested topics.

**The classic question.** A configuration uses `count` over a list, an element is removed from the middle, and you are asked what the plan does. The answer is that resources after the removed element are destroyed and recreated. The distractor is "only the removed resource is destroyed", which is the `for_each` answer.

**`count` produces a list, `for_each` produces a map.** A question showing `resource.name[0]` versus `resource.name["key"]` is testing which meta-argument was used.

**`count = 0`.** The resource exists in configuration but no instances are created. It is not an error, and the resource still appears in the configuration graph.

Also worth knowing: `count` and `for_each` cannot both be set on the same resource. It is a hard error, and it appears as a distractor in questions about conditionally creating multiple resources.
