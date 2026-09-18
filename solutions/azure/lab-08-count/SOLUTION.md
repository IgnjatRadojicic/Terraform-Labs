# Solution: Azure Lab 08, count

Pairs with **AWS lab 08**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| What repeats | **buckets** — S3 has no grouping layer | **containers** inside one storage account |
| Resources created | 6 | **8** (2 are scaffolding) |
| Blast radius of the count bug | severe — buckets destroyed | **milder** — containers destroyed |
| Can you observe the bug | yes, real state via LocalStack | **no, plan-only** |

## Walkthrough

### The unit of repetition changed

On AWS, three zones meant three buckets, because S3 has nothing between a bucket and an account.

On Azure, three zones means **one storage account with three containers**, because Azure does have that layer. The resource group and storage account are created once; only the containers and workspaces repeat.

```hcl
resource "azurerm_storage_container" "zone" {
  count = length(var.zones)

  name               = var.zones[count.index]
  storage_account_id = azurerm_storage_account.main.id
}
```

The Terraform is identical to the AWS version. `count` takes a number, `count.index` is the iteration from 0, and the splat operator pulls one attribute from every instance:

```hcl
output "container_names" {
  value = azurerm_storage_container.zone[*].name
}
```

That is why the plan is 8 rather than 6 — same three-zone idea, two extra Azure objects.

### The honest limitation of this lab

The AWS version's payoff was step 7: remove a middle zone, watch the plan destroy four resources and recreate two.

**This track cannot show you that**, and I am not going to pretend otherwise. Azure is plan-only here, so state is always empty and every plan reads "N to add". The destruction is real and invisible.

So the evidence lives in your AWS lab 08 notes. What it showed:

```
$ terraform plan -var='zones=["raw","curated"]'
  # aws_s3_bucket.zone[1] must be replaced
  # aws_s3_bucket.zone[2] will be destroyed
Plan: 2 to add, 0 to change, 4 to destroy.
```

`count` identifies instances by **position**. State holds `zone[0]=raw`, `zone[1]=staging`, `zone[2]=curated`. Remove `staging` and everything after shifts down, so `zone[1]` must be renamed from staging to curated. A name is an identity, so that means destroy and recreate. `zone[2]` no longer exists and is destroyed outright.

One zone removed. Four resources destroyed, two recreated, including one you never touched.

### Why Azure's version is milder, and why that is a trap

A container is cheaper to destroy and recreate than a bucket, and the storage account above it is untouched. So the same bug costs less here.

Do not take comfort from that. Point the same configuration at storage accounts rather than containers — which you would, the moment each zone needs its own account for access isolation — and it is exactly as destructive as the AWS case. The mildness is a property of what you chose to repeat, not of the provider.

## Why not the alternative

**Tempting: one storage account per zone, mirroring AWS's one bucket per zone.**

```hcl
resource "azurerm_storage_account" "zone" {
  count = length(var.zones)
  name  = "st${var.project_name}${var.zones[count.index]}"
}
```

Closer to the AWS shape and worse for three reasons. Storage account names are globally unique, so collisions are likely. Each account is a separate billing and access-control boundary you probably do not want per zone. And it maximises the blast radius of exactly the bug this lab exists to teach.

Containers are the right granularity for data zones. Use separate accounts when you need separate access boundaries, not merely separate names.

**Tempting: `count` with a sorted list, so ordering is deterministic.**

```hcl
count = length(sort(var.zones))
```

Deterministic assignment is not **stable** assignment. Sorting `["raw","staging","curated"]` gives `["curated","raw","staging"]`, and removing `raw` still shifts `staging` down. Only stability matters, and only `for_each` provides it.

## Verification transcript

```
$ terraform plan
Plan: 8 to add, 0 to change, 0 to destroy.

$ terraform plan -var='zones=["raw","staging","curated","archive"]'
Plan: 10 to add, 0 to change, 0 to destroy.
```

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0. **Plan only** — the destructive middle-removal case cannot be demonstrated on this track and is cited from the AWS lab instead.

## Exam connection

Entirely provider-agnostic; your AWS notes apply unchanged.

**`count` produces a list**, addressed `[0]`, `[1]`. **`for_each` produces a map**, addressed by key.

**Removing a middle element under `count`** destroys and recreates everything after it. The classic question, with "only the removed resource is destroyed" as the `for_each` distractor.

**`count` and `for_each` cannot both be set** on one resource.

**Splat expressions** `[*]` pull an attribute from every instance.
