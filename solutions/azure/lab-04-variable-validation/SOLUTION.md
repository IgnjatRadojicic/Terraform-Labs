# Solution: Azure Lab 04, Variable validation

Pairs with **AWS lab 04**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Naming rules | 3–63 chars, hyphens and dots allowed | **3–24, lowercase alphanumeric only** |
| Who catches a bad name | provider, sometimes | **the API, at apply, after the RG exists** |
| Value of validation | good | **higher** — rules are stricter and less guessable |
| Uniqueness | global (S3) | global (storage accounts) |

The validation *mechanism* is identical. Azure just gives it more to do.

## Walkthrough

### One rule per block

```hcl
validation {
  condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
  error_message = "Storage account names must be 3 to 24 characters. Got ${length(var.storage_account_name)}."
}

validation {
  condition     = can(regex("^[a-z0-9]+$", var.storage_account_name))
  error_message = "Storage account names allow only lowercase letters and digits."
}
```

Terraform evaluates **every** validation block and reports each failure separately. Two blocks tell the caller which rule they broke; one combined condition tells them only that something is wrong.

Verified, each failure mode caught by the right rule:

```
st-labs-validation           -> "only lowercase letters and digits"
stabcdefghijklmnopqrstuvw    -> "3 to 24 characters. Got 25"
stLabsValidation             -> "only lowercase letters and digits"
location=eastus              -> "Location must be one of: uksouth, ..."
```

Note the first one. `st-labs-validation` is a **perfectly legal S3 bucket name**. Carrying an AWS naming habit across is exactly the mistake this rule catches.

### Why this matters more on Azure

Without validation, a bad storage account name fails at **apply**, from the Azure API, *after* the resource group has already been created. You are left with a half-built deployment and an error from a service rather than from Terraform.

With validation it fails at plan, before anything exists, with a message you wrote.

On AWS the provider often catches naming problems itself, so the validation block is belt-and-braces. On Azure it is doing real work.

### What validation still cannot catch

Global uniqueness. A name can satisfy every rule above and still fail at apply because someone else in the world already registered it.

No validation block can check that, because it needs a round trip to Azure. Plan-time validation moves *most* failures earlier. It does not move all of them, and believing otherwise is how you end up surprised.

## Why not the alternative

**Tempting: one regex that enforces length and characters together.**

```hcl
condition = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
```

Correct, shorter, and worse. A caller who passes a 25-character valid-charset name gets told about the character rule, which is not what they broke. They then stare at a name containing only lowercase letters and digits, wondering what the message means.

Split the rules so each message is true.

**Tempting: skip validation and let Azure reject it.**

Azure's message is accurate and arrives at the worst possible moment, mid-apply, referencing a resource type rather than your variable. It also does not tell the caller which of *your* variables was at fault when the name is assembled from several.

**Tempting: `startswith`/`endswith` instead of regex.**

Fine for prefixes, insufficient here. The rule is about every character in the string, which is what a regex is for. `can(regex(...))` is the idiom, and `can()` is required because `regex()` raises rather than returning false on no match.

## Verification transcript

```
$ terraform plan
Plan: 2 to add, 0 to change, 0 to destroy.
```

All four rules confirmed firing against a real subscription, each failure matched to the correct rule, with Terraform 1.16.0 and azurerm 4.81.0. Plan only.

## Exam connection

**`validation` blocks live inside `variable` blocks** and fail at plan time.

**`can()` wraps an expression that might error** and returns a boolean. `regex()` raises on no match, so `can(regex(...))` is the standard pairing — this exact combination is examinable.

**Multiple validation blocks per variable are allowed**, and all are evaluated.

**Validation cannot reference resources**, only variables (and, since 1.9, other variables). Rules involving a resource attribute need a `precondition`, which is lab 22.
