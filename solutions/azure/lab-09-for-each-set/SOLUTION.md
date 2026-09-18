# Solution: Azure Lab 09, for_each over a set

Pairs with **AWS lab 09**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Terraform used | `for_each`, `toset()` | **identical** |
| What repeats | buckets | containers |
| Resources | 6 | 8 |
| Key stability | proven with real state | **cited from the AWS lab** |

This is the lab where the two tracks converge most completely. Strip the resource type names and the configurations are the same file.

## Walkthrough

### The deliberate failure

```hcl
for_each = var.zones      # list(string)
```

```
Error: Invalid for_each argument

  The given "for_each" argument value is unsuitable: the "for_each"
  argument must be a map, or set of strings, and you have provided a
  value of type list of string.
```

Identical message to the AWS track, because this is Terraform core rather than the provider. Worth meeting once on purpose.

### Why a list is refused

Not arbitrary. `for_each` identifies each instance by a **key**, and that key becomes part of the resource address in state. A list has order but no keys. Using position as the key would reintroduce the lab 08 problem exactly, so Terraform refuses rather than doing the wrong thing quietly.

```hcl
for_each = toset(var.zones)
```

`toset()` discards order and removes duplicates — and both of those are precisely why the result is stable.

### each.key and each.value are the same thing here

```hcl
name = each.key      # identical to each.value for a set
```

A set has no separate keys, so Terraform uses the element itself as both. With a map they genuinely differ, which is lab 10.

### Addressing is the whole difference

```hcl
output "container_names" {
  value = { for k, c in azurerm_storage_container.zone : k => c.name }
}

output "curated_container" {
  value = azurerm_storage_container.zone["curated"].name    # by key, not [2]
}
```

Lab 08 produced a positional list. This produces a map:

```
container_names = {
  "curated" = "curated"
  "raw"     = "raw"
  "staging" = "staging"
}
instance_keys = ["curated", "raw", "staging"]
```

Self-describing. A caller reading the map knows what they have; a caller reading `["curated", "raw", "staging"]` has to know the ordering convention. For anything crossing a team boundary, that settles it.

Note the map keys come back **sorted**, which is always true of Terraform maps and is not evidence that anything reordered.

### The stability claim, honestly sourced

Plan-only means empty state, so this track cannot demonstrate that removing a middle zone destroys only that zone. From your AWS lab 09:

```
$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone["staging"] will be destroyed
Plan: 0 to add, 0 to change, 2 to destroy.
```

Against lab 08's four destroyed and two recreated for the identical edit. And reordering the list produced `No changes` rather than lab 08's near-total replacement.

## Why not the alternative

**Tempting: change the variable's type to `set(string)` and drop `toset()`.**

Works, and usually the wrong trade. A `list` is pleasanter for callers to write, and it is what a caller producing the value from a `for` expression or a data source already has. Accept the convenient type and convert internally — that is what published modules do.

The one case for declaring `set(string)`: when duplicates in the input are a caller error you want surfaced. `toset()` silently deduplicates, so `["raw","raw"]` becomes one container with no warning.

**Tempting: satisfy `for_each` by generating keys from indices.**

```hcl
for_each = { for i, z in var.zones : i => z }
```

This type-checks and reintroduces the lab 08 bug exactly, because the keys are now `"0"`, `"1"`, `"2"`. The checker is happy and the behaviour is wrong, which is the worst combination.

If you are generating keys from indices, stop. Keys should come from the data's own identity.

## Verification transcript

```
$ terraform validate        # with for_each = var.zones
Error: Invalid for_each argument
  ... must be a map, or set of strings, and you have provided a value of type list

$ terraform plan            # with toset()
Plan: 8 to add, 0 to change, 0 to destroy.
```

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0. **Plan only** — the key-stability comparison is cited from the AWS lab.

## Exam connection

**`for_each` accepts a map or a set of strings, never a list.** Asked directly and often.

**`toset()`** performs the conversion.

**`each.key` and `each.value`** are identical for a set, different for a map.

**Keys must be known at plan time.** A key derived from a `(known after apply)` attribute errors. Common when chaining modules; the fix is keying off configuration rather than computed values.
