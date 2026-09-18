# Solution: Azure Lab 10, for_each over a map

Pairs with **AWS lab 10**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Per-instance setting | `versioned` bool, somewhat contrived | **`container_access_type`** — a real security decision |
| Filtered resource | `aws_s3_bucket_versioning` | an extra audit container |
| Resources | 8 | **10** |
| Naming quirk | none | **container names allow hyphens, account names do not** |

## Walkthrough

### Key and value now mean different things

```hcl
resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  container_access_type = each.value.access_type
}
```

With a set they were the same value. With a map:

- `each.key` — `"uploads"`, the map key, which becomes the resource address
- `each.value` — `{ access_type = "private", retention_days = 30, audited = true }`

That is why a map is the general case and a set is the simple one. A set says *which* instances exist. A map says which exist **and how each is configured**.

### The per-instance setting actually matters here

```
access_types = {
  "public-assets" = "blob"
  "reports"       = "private"
  "uploads"       = "private"
}
```

`blob` makes the container's contents **publicly readable over the internet**. That is a real security decision expressed as one word inside a map.

It is also a good argument for the type constraint being `map(object({...}))` rather than `map(any)`. With a precise type, a caller who misspells `access_type` gets an error. With `any`, they get a silently missing field — and lab 11 shows that extra attributes are discarded without warning, which for a security setting is a bad way to find out.

### Filtering, not flagging

```hcl
resource "azurerm_storage_container" "audit" {
  for_each = { for k, v in var.containers : k => v if v.audited }

  name = "${each.key}-audit"
}
```

The `for` expression produces a map containing only audited entries. That map is still a valid `for_each` argument, so the resource simply has fewer instances.

Total: 1 resource group + 1 storage account + 3 containers + 3 workspaces + **2** audit containers = 10. If you counted 11, the filter is not filtering.

Why this beats creating one for everything and leaving it unused: an unused container is a real object that exists, appears in audits, and has to be explained. Filtering means it was never created. And when you flip `audited` from true to false, filtering **destroys** the container while a flag would merely modify it — only one of those is what you meant.

### Indexing another for_each resource by the same key

```hcl
storage_account_id = azurerm_storage_account.main.id
```

Here the account is a single resource so this is a plain reference. Where you *do* need to reach a sibling instance — as the workspace-to-container wiring would in a larger version — index by the same key:

```hcl
workspace_id = azurerm_log_analytics_workspace.this[each.key].id
```

Rebuilding the name as a string would produce the same value and create no dependency edge, which is lab 07's lesson.

### The naming quirk

`public-assets` contains a hyphen and is a perfectly legal container name, even though the storage account containing it cannot have one. Azure's naming rules are per resource type, and there is no shortcut but the documentation.

## Why not the alternative

**Tempting: two variables — a map of containers and a list of audited names.**

```hcl
variable "containers"        { type = map(object({...})) }
variable "audited_containers" { type = list(string) }
```

Now nothing stops someone listing a container in `audited_containers` that does not exist in `containers`. You have created a referential integrity problem that the single map made impossible to express.

Keeping related configuration in one structure is a correctness property, not tidiness.

**Tempting: `map(any)` so entries can vary in shape.**

`any` is not a passthrough — it forces type unification. AWS lab 14 shows `map(any)` collapsing to `map(map(string))` and silently turning the number `90` into the string `"90"`. Here that would turn `retention_days` into a string and `audited` into `"true"`, and `if v.audited` on a non-empty string is always true, so **every** container would get an audit container.

A precise type prevents that entirely.

## Verification transcript

```
$ terraform plan
Plan: 10 to add, 0 to change, 0 to destroy.
```

Three containers with three different access types, three workspaces with three different retentions, two audit containers from the filtered map.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

One practical note: an earlier draft of this lab used `azurerm_log_analytics_storage_insights` for the filtered resource. It works, and its plan takes over ten minutes because the provider performs slow lookups against the storage account. It was replaced with an audit container, which plans in about thirteen seconds. If a lab of your own suddenly plans slowly, suspect a resource that reads keys or performs cross-service lookups.

## Exam connection

**`each.key` versus `each.value` with a map.** The key is the map key; the value is whatever the map holds there.

**`for_each` accepts a map of objects.** The restriction is on the top-level collection type, not its contents.

**Filtering with a `for` expression inside `for_each`.** Count the entries surviving the `if`.

**Keys must be known at plan time**, which is why keys come from configuration rather than computed attributes.
