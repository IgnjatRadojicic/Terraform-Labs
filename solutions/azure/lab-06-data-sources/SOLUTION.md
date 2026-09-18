# Solution: Azure Lab 06, Data sources versus resources

Pairs with **AWS lab 06**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Identity data source | `aws_caller_identity` | `azurerm_client_config` |
| Returns | account ID, ARN, user ID | **subscription ID, tenant ID, object ID** |
| Identity hierarchy | account | **tenant → subscription** |
| Arguments needed | none | none |

## Walkthrough

### A data source reads; it does not own

```hcl
data "azurerm_client_config" "current" {}
```

No arguments. It reports the identity Terraform is currently authenticated as.

The plan reports **2 to add**, not 3. Data sources are not counted, because reading is not creating. That single number is the clearest statement of the distinction:

| | Terraform creates it | Terraform destroys it | Counted in plan |
|---|---|---|---|
| `resource` | yes | yes | yes |
| `data` | no | **no** | no |

### Data source values are known at plan time

```
subscription_id = "38d9b32c-47be-4b57-908c-1aa46043d0bb"    real value in the plan
storage_account_id = (known after apply)                     cannot exist yet
```

Data sources are read **during** plan, so their values are available immediately. Resource attributes cannot be known until the resource exists.

This is why a data source can feed a `for_each` key and a resource attribute usually cannot — the keys must be known at plan time, which is a constraint you meet properly in lab 10.

### The extra hierarchy layer

AWS has an account. Azure has a **tenant** containing **subscriptions**.

| Layer | What it is |
|---|---|
| Tenant | an Entra ID directory — the identity boundary |
| Subscription | the billing and resource boundary |
| Resource group | the lifecycle boundary |

AWS collapses the first two into one account ID. This matters more than it first appears: it is why Azure role assignments reference a *scope path* rather than an ARN, and why lab 21's provider aliasing has more to configure on Azure than on AWS. An aliased AWS provider usually differs by region; an aliased Azure provider often differs by subscription *within the same tenant*.

### What destroy would do

Nothing to the subscription. Terraform never owned it — it only read facts about it. `destroy` removes the resource group and the storage account.

That is the entire point of a data source, and it is why reading an existing resource group with `data "azurerm_resource_group"` is safer than declaring one you did not create. Declare it as a resource and `destroy` deletes it **and everything inside it**, including things other teams put there.

On Azure that mistake is considerably worse than on AWS, because resource group deletion cascades.

## Why not the alternative

**Tempting: hardcode the subscription ID, you know what it is.**

```hcl
tags = { Subscription = "38d9b32c-47be-4b57-908c-1aa46043d0bb" }
```

It works in exactly one subscription. The same configuration applied to staging tags everything with production's ID, silently, and the tag is now actively misleading rather than merely absent.

Reading it means the configuration is correct wherever it runs.

**Tempting: use a `data "azurerm_resource_group"` for a group you are also creating.**

You cannot, and Terraform will tell you — the data source reads at plan time, before the resource exists. Either create it or read it, never both. Choosing which is a real design decision: create it when this configuration owns its lifecycle, read it when someone else does.

## Verification transcript

```
$ terraform plan
Plan: 2 to add, 0 to change, 0 to destroy.
```

Two resources, one data source, and the data source is not counted. `subscription_id` and `tenant_id` carry real values during plan; the storage account's computed attributes show `(known after apply)`.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

## Exam connection

**Data sources are read, not created**, and `destroy` does not touch them. Directly examinable.

**Data sources are resolved at plan time**, which is why their values can be used where resource attributes cannot.

**`data` blocks count toward nothing in the plan summary.** A question showing a plan count with data sources present is testing this.

**Ownership is the real distinction.** If Terraform should create and destroy it, it is a resource. If it already exists and belongs to someone else, it is a data source.
