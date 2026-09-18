# Solution: Azure Lab 01, Provider configuration and first resource

Pairs with **AWS lab 01**. Read them side by side.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Provider block | works with no arguments | **`features {}` is mandatory** |
| Grouping layer | none above a bucket | **resource group, required** |
| Region | provider-level | **per resource** (`location`) |
| Storage naming | 3–63, hyphens allowed | **3–24, lowercase alphanumeric only** |
| Durability | implicit | **explicit** (`account_tier`, `account_replication_type`) |
| Verification | full `apply` via LocalStack | `plan` only |

Same Terraform. Four extra decisions Azure forces you to make.

## Walkthrough

### The features block

```hcl
provider "azurerm" {
  features {}
}
```

Empty and required. It configures per-resource-type behaviours — for example whether destroying a resource group also purges soft-deleted key vaults inside it. Most people leave it empty forever.

**The reason this is step 8 of the lab:** removing it produces this pair of results, which I verified against azurerm 4.81.0:

```
$ terraform validate
Success! The configuration is valid.        exit 0

$ terraform plan
Error: Missing required argument
  The argument "features" is required, but no definition was found.
```

`validate` checks syntax and internal consistency. It does **not** check that a provider is correctly configured, because that is a runtime concern. So the configuration is simultaneously "valid" and unable to run.

Carry this forward. "terraform validate passed" is a far weaker statement than most people treat it as, and this is the cleanest demonstration of it in either track.

### Resource groups have no AWS equivalent

```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-labs"
  location = "uksouth"
}
```

Every Azure resource lives in exactly one resource group. It is free, it is a real object with a lifecycle, and **deleting it deletes everything inside it**.

That last property has no S3 analogue and is worth respecting early. It is also why the Azure track's module design (lab 18) differs from AWS's: a module that creates its own resource group can never place resources in an existing one, and in Azure that is nearly always what you actually need.

### Storage account naming

```hcl
name = "stterraformlabs001"
```

3 to 24 characters, lowercase letters and digits only, globally unique across all of Azure.

`terraform-labs-storage` is a legal S3 bucket name and an illegal storage account name. The AWS habit of `"${var.project}-${var.component}"` does not survive the move, which is why lab 05 pushes name construction into locals.

`account_tier` and `account_replication_type` have no S3 counterpart either. S3 has one tier and handles durability for you; Azure makes both explicit. `Standard` and `LRS` are the cheapest pair and correct for every lab here.

## Why not the alternative

**Tempting: skip the resource group by reusing an existing one.**

You would use a `data "azurerm_resource_group"` block instead of a resource. That is genuinely correct in production, where the resource group is usually created by a platform team and you place things inside it.

It is wrong for lab 01 because you would then be building on something whose lifecycle you do not control, and the lab is about seeing the whole chain. Lab 06 covers the data-source version properly.

**Tempting: set the region once on the provider, as on AWS.**

```hcl
provider "azurerm" {
  features {}
  # there is no `location` argument here
}
```

There isn't one. Azure has no provider-level default location — every resource that needs one declares it. The idiom is to set it on the resource group and have everything else inherit:

```hcl
location = azurerm_resource_group.main.location
```

which also creates the dependency edge, so it is doing two jobs. That is the pattern used throughout this track.

## Verification transcript

```
$ terraform plan
Plan: 2 to add, 0 to change, 0 to destroy.
```

With `features {}` removed:

```
$ terraform validate
Success! The configuration is valid.

$ terraform plan
Error: Missing required argument
  The argument "features" is required, but no definition was found.
```

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only. Nothing was applied.

## Exam connection

The Terraform Associate is provider-agnostic, so nothing here is examined as Azure knowledge. What **is** examinable is the general shape:

**Provider configuration is not checked by `validate`.** Questions about the difference between `validate` and `plan` are common, and this is the sharpest example.

**Provider version pinning** with `required_providers` works identically across providers.

**Some providers require configuration blocks.** The exam will not ask about `features {}` by name, but it may ask whether `validate` guarantees a runnable configuration. It does not.
