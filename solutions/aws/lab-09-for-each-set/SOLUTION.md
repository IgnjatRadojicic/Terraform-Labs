# Solution: Lab 09, for_each over a set

## Approach

Identical infrastructure to Lab 08, built with `for_each` over `toset(var.zones)`. The configuration is barely different. The behaviour under change is completely different, and that comparison is the entire value of doing both labs.

## Walkthrough

### The deliberate failure

```hcl
for_each = var.zones      # var.zones is list(string)
```

```
Error: Invalid for_each argument

  The given "for_each" argument value is unsuitable: the "for_each"
  argument must be a map, or set of strings, and you have provided a
  value of type list of string.
```

Terraform tells you exactly what it accepts and exactly what you gave it. This is worth meeting once deliberately, because it is among the most frequent errors in real Terraform and the fix is not obvious if you have never seen it.

### Why a list is refused

This is not an arbitrary restriction, and understanding it makes the rest of `for_each` obvious.

`for_each` identifies each instance by a **key**, and that key becomes part of the resource address stored in state. A list has an order but no keys. Using the position as a key would reintroduce exactly the Lab 08 problem, so Terraform refuses rather than doing the wrong thing quietly.

A set has no order, so there is nothing to shift. The element itself is the key.

```hcl
for_each = toset(var.zones)
```

`toset()` does two things worth knowing: it **discards order** and it **removes duplicates**. Both are fine here, and both are precisely why the result is stable.

### each.key and each.value are the same thing

With a set, these are identical:

```hcl
bucket = "${var.project_name}-${each.key}"
name   = "/aws/${var.project_name}/${each.value}"
```

That surprises people. A set has no separate keys, so Terraform uses the element as both. With a map they genuinely differ, which is Lab 10.

### The addresses are the difference

```
aws_s3_bucket.zone["curated"]
aws_s3_bucket.zone["raw"]
aws_s3_bucket.zone["staging"]
```

Compare Lab 08's `[0]`, `[1]`, `[2]`. The address now contains the zone's identity rather than its position, and identity does not shift when a neighbour is removed.

### The same edit, the other outcome

```
$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone["staging"] will be destroyed
Plan: 0 to add, 0 to change, 2 to destroy.
```

Side by side with Lab 08, for the identical edit:

| | Lab 08, `count` | Lab 09, `for_each` |
|---|---|---|
| Destroyed | 4 | 2 |
| Recreated | 2 | 0 |
| Untouched resources harmed | 2 | 0 |

And reordering is now a non-event:

```
$ terraform plan -var='zones=["curated","raw","staging"]'
No changes. Your infrastructure matches the configuration.
```

Lab 08 would have proposed replacing nearly everything for the same reordering, because every index changed. Here nothing changed, because no key changed.

### Referencing a for_each resource

A `for_each` resource is a **map**, so:

```hcl
value = aws_s3_bucket.zone["curated"].bucket              # by key
value = { for k, b in aws_s3_bucket.zone : k => b.bucket } # whole map
value = sort(keys(aws_s3_bucket.zone))                     # just the keys
```

There is no `[0]`. The splat operator from Lab 08 does work on a `for_each` resource, but it returns values in an unspecified order, so it is rarely what you want.

## Why not the alternative

**The tempting approach: change the variable's type to `set(string)` instead of converting at the point of use.**

```hcl
variable "zones" {
  type = set(string)     # instead of list(string)
}
```

This works and removes the need for `toset()`. It is usually the wrong trade.

A `list` is pleasanter for callers. It is written in an obvious order, it reads naturally in a tfvars file, and it is what a caller producing the value from a `for` expression or a data source will already have. A `set` forces every caller to think about a distinction that is your implementation detail, not theirs.

The standard shape in published modules is to **accept the convenient type and convert internally**. Your interface stays friendly and your implementation stays stable. The same reasoning applies to accepting `list(object)` and converting to a map, which is Lab 11.

There is one case where declaring `set(string)` is right: when duplicates in the input are genuinely a caller error you want surfaced. `toset()` silently deduplicates, so `["raw","raw"]` becomes one bucket with no warning. If that should be an error, the type should say so, or a `validation` block should catch it.

**A second tempting approach: use `for_each` with a list by converting positions to keys.**

```hcl
for_each = { for i, z in var.zones : i => z }
```

This satisfies `for_each` and reintroduces the Lab 08 bug exactly, because the keys are now `"0"`, `"1"`, `"2"`. Removing a middle element shifts them all. The type checker is happy and the behaviour is wrong, which is the worst combination.

If you find yourself generating keys from indices, stop. The keys should come from the data's own identity.

## Verification transcript

```
$ terraform validate          # with for_each = var.zones
Error: Invalid for_each argument
  var.zones is a list of string
  must be a map, or set of strings, and you have provided a value of type list

$ terraform apply -auto-approve    # with toset()
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

$ terraform state list
aws_cloudwatch_log_group.zone["curated"]
aws_cloudwatch_log_group.zone["raw"]
aws_cloudwatch_log_group.zone["staging"]
aws_s3_bucket.zone["curated"]
aws_s3_bucket.zone["raw"]
aws_s3_bucket.zone["staging"]

$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone["staging"] will be destroyed
Plan: 0 to add, 0 to change, 2 to destroy.

$ terraform plan -var='zones=["curated","raw","staging"]'
No changes. Your infrastructure matches the configuration.
```

Verified against LocalStack with Terraform 1.16.0 and AWS provider 6.64.0.

## Exam connection

**What types does `for_each` accept?** A map, or a set of strings. Not a list. This is asked directly and often.

**How do you convert?** `toset()` for a list of strings. A `for` expression for anything needing real keys.

**`each.key` versus `each.value`.** Identical for a set, different for a map. A question may show a set and ask what `each.value` contains.

**Addressing.** `for_each` instances are addressed by key in quotes and brackets, and this matters for `terraform state` commands in Tier 4, where you will need to quote and escape those addresses on the command line.

Worth carrying forward: `for_each` keys must be known at plan time. A key derived from an attribute that is `(known after apply)` produces an error telling you Terraform cannot determine the instance keys. That error is common when chaining modules, and the fix is to key off configuration rather than off computed values.
