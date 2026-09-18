# Solution: Azure Lab 05, Local values

Pairs with **AWS lab 05**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Why locals | stop repeating a tag map | **that, plus reconciling contradictory naming rules** |
| Naming rules | consistent enough to ignore | **differ per resource type** |
| Tag mechanics | identical | identical |

On AWS, locals were a tidiness win. On Azure they are load-bearing.

## Walkthrough

### Two naming conventions that cannot be one

```hcl
locals {
  name_prefix  = "${var.project_name}-${var.environment}"
  storage_name = lower(replace("st${var.project_name}${var.environment}", "-", ""))
}
```

Resource groups allow hyphens. Storage accounts forbid them. Containers allow them. There is no single string that satisfies all three, so something must convert, and locals is the one place you can do it once.

With defaults this gives:

```
name_prefix  = "platform-dev"
storage_name = "stplatformdev"
```

The alternative is writing `replace(...)` at every use site, getting it right most times, and producing one storage account that differs from the others by a character. That bug is invisible in review and obvious in production.

### storage_name is derived, not declared

The lab forbids making `storage_name` its own variable, and the reason is worth stating.

A separate variable lets a caller set `project_name = "orders"` and `storage_name = "stpayments"`. Now the resource group says orders and the storage account says payments, and nothing anywhere objects. Deriving it makes that state impossible to express.

The general rule: **if a value is a function of other values, compute it — do not accept it.** Every independently settable input is a way for the configuration to contradict itself.

### merge order is not cosmetic

```hcl
common_tags = merge(
  {
    ManagedBy   = "Terraform"
    Environment = var.environment
  },
  var.extra_tags          # last, so the caller wins
)
```

Later arguments win. Putting `var.extra_tags` first would mean your defaults silently overwrite whatever the caller passed — they would set `Environment = "prod"` and get `"dev"`, with no error and no warning.

Merging `{}` is a no-op, so a caller who passes nothing gets exactly the defaults.

### locals cannot be overridden

This is the part people miss. A `local` is not a `variable`:

| | Settable by caller | Can reference resources |
|---|---|---|
| `variable` | yes | no |
| `local` | **no** | yes |

That is a feature. `name_prefix` is an internal derivation, and exposing it as a variable would invite exactly the contradiction described above.

## Why not the alternative

**Tempting: put the tags in a variable default instead of a local.**

```hcl
variable "tags" {
  default = { ManagedBy = "Terraform", Environment = "dev" }
}
```

A variable default is **replaced wholesale**, never merged. The moment a caller supplies their own map, your defaults vanish entirely and every tag must be respecified.

This is the same lesson as AWS lab 05 and it recurs in lab 12's `optional()`: a variable default is an all-or-nothing fallback, while `merge()` and `optional()` compose per key.

**Tempting: build names with `format()` for clarity.**

```hcl
storage_name = format("st%s%s", var.project_name, var.environment)
```

Equivalent and arguably cleaner, but it does not strip hyphens, so it fails the moment `project_name` contains one. `replace()` is doing the real work here; `format()` is only about presentation.

## Verification transcript

```
$ terraform plan
Plan: 3 to add, 0 to change, 0 to destroy.
```

With defaults, `name_prefix = "platform-dev"` and `storage_name = "stplatformdev"`. Supplying `extra_tags` layers over the defaults rather than replacing them.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

## Exam connection

**`locals` cannot be set from outside.** Only `variable` accepts input. Directly examinable and a common distractor.

**`locals` can reference resources and data sources; `variable` defaults cannot.** A `variable` default referencing another variable is an error — "Variables not allowed" — which is exactly why this computation lives in locals.

**`merge()` precedence: later wins.** Reliably examinable on its own.

**A local is evaluated once per configuration**, not per reference, so referencing it ten times costs nothing.
