# Solution: Azure Lab 02, Input variables

Pairs with **AWS lab 02**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Versioning | separate `aws_s3_bucket_versioning` resource | **nested `blob_properties` block** on the account |
| Name interpolation | `"${var.project}-uploads"` works | **hyphen illegal**, must be `"st${var.project}uploads"` |
| Log retention | `aws_cloudwatch_log_group.retention_in_days` | `azurerm_log_analytics_workspace.retention_in_days` + a required `sku` |
| Resources for the same job | 3 | 3, but one is scaffolding |

The variable mechanics — types, defaults, tfvars, `-var` precedence — are **identical**. Nothing about Terraform's variable system changes between providers, which is the reassuring half of this lab.

## Walkthrough

### Versioning moved inside the resource

```hcl
resource "azurerm_storage_account" "uploads" {
  # ...
  blob_properties {
    versioning_enabled = var.enable_versioning
  }
}
```

On AWS this was a whole separate resource with its own address in state. On Azure it is a nested block on the account.

That trade-off has consequences beyond tidiness:

- **Fewer resources to manage.** No separate `for_each`, no separate import.
- **Less independently addressable.** You cannot import, move or destroy the versioning setting on its own, because it is not a separate object.
- **Different plan output.** Toggling it shows as a *modification* of the storage account rather than the creation or destruction of a separate resource.

Neither design is better. They fail differently, and knowing which you are holding matters when you reach imports.

### The naming break

```hcl
name = "st${var.project_name}uploads"     # no separator
```

The AWS pattern `"${var.project_name}-uploads"` is rejected. Hyphens are illegal in storage account names.

This is the first place the two tracks genuinely diverge in how you write Terraform rather than just which resources you name. It is also why lab 05 exists in the form it does: once you have several resource types with contradictory naming rules, the reconciliation has to live somewhere findable.

### Log Analytics needs a SKU

```hcl
resource "azurerm_log_analytics_workspace" "main" {
  sku               = "PerGB2018"
  retention_in_days = var.retention_days
}
```

`PerGB2018` is the current standard tier and what you want. CloudWatch has no equivalent argument — AWS decided the pricing model for you.

Note that Log Analytics has a free ingestion allowance (5 GB/month at time of writing) but the workspace object itself costs nothing to exist, which is why these labs use it freely.

## Why not the alternative

**Tempting: keep the AWS naming convention and sanitise later.**

```hcl
name = replace("${var.project_name}-uploads", "-", "")
```

This works and is what lab 05 formalises. Doing it inline at every use site is the problem — you will write it four times, get it right three times, and the fourth produces a name that differs from the other three by one character.

Compute it once in `locals` and reference it. That is lab 05's whole argument, and Azure gives it more force than AWS did.

**Tempting: make `enable_versioning` a string so you can pass "true"/"false".**

Terraform would convert it, and you would lose type checking for nothing. `bool` is correct. The same reasoning as the AWS lab: the type constraint is documentation that the compiler enforces.

## Verification transcript

```
$ terraform plan
Plan: 3 to add, 0 to change, 0 to destroy.
```

Resource group, storage account, Log Analytics workspace. `retention_in_days` resolves to 90 from `terraform.tfvars`, overriding the default of 30, and to 7 with `-var`.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

## Exam connection

Everything examinable here is provider-agnostic and identical to the AWS lab:

**Variable precedence**, lowest to highest: defaults, environment variables, `terraform.tfvars`, `*.auto.tfvars` alphabetically, `-var-file`, `-var`.

**Type constraints** are enforced and conversion is attempted before rejection.

**A variable default is replaced wholesale**, never merged — which is why lab 05 uses `merge()` rather than relying on defaults.
