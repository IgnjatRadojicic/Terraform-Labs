# Solution: Azure Lab 03, Outputs and resource attributes

Pairs with **AWS lab 03**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Resource identifier | ARN, flat-ish | **full ARM path** encoding the whole containment chain |
| Identity layers | account | **tenant → subscription → resource group** |
| Secret attributes | rare on S3 | **common** — keys and connection strings everywhere |
| Sensitivity source | you mark it | **the provider marks it** |

## Walkthrough

### The resource ID is the important one

```
/subscriptions/38d9b32c-.../resourceGroups/rg-reporting/providers/Microsoft.Storage/storageAccounts/streportingdata
```

Compare against `arn:aws:s3:::reporting-data`.

The Azure form encodes the entire hierarchy: subscription, resource group, provider namespace, resource type, name. It is long, and it is the string you will paste into `import` blocks in Tier 4.

This is the single most practical difference between importing on the two clouds. An AWS S3 import ID is just the bucket name. An Azure import ID is that whole path, and getting one character wrong produces a confusing "resource not found" rather than a clear error.

### workspace_id is not the resource ID

```hcl
output "workspace_id" {
  value = azurerm_log_analytics_workspace.audit.workspace_id
}
```

Log Analytics exposes two identifiers and they are not interchangeable:

| Attribute | What it is | Use for |
|---|---|---|
| `id` | the ARM resource path | referencing from other Terraform resources, imports |
| `workspace_id` | a GUID, the "customer ID" | agent configuration, query APIs |

Use `id` when wiring Terraform resources together. `workspace_id` is for things outside Terraform that need to talk to the workspace. Mixing them up produces errors that do not explain themselves.

### The provider decides what is sensitive

```hcl
output "primary_access_key" {
  value     = azurerm_storage_account.data.primary_access_key
  sensitive = true      # required, not optional
}
```

Omit `sensitive = true` and Terraform refuses:

```
Error: Output refers to sensitive values
```

You never marked anything. **The provider marks `primary_access_key` sensitive in its schema**, and that marking is contagious — anything derived from it inherits it, and a root module output carrying it must acknowledge it.

This is the same rule as AWS lab 24, but you meet it here in lab 03 rather than lab 24, because Azure resources expose keys and connection strings as ordinary attributes far more often than S3 does.

Worth carrying forward: this protects *display*, not storage. That key is in your state file in plain text regardless. AWS lab 24 proves that with a `grep`; the Azure equivalent would be identical.

## Why not the alternative

**Tempting: output the connection string instead, it's more useful.**

```hcl
value = azurerm_storage_account.data.primary_connection_string
```

It is more useful, and it is also more dangerous, because it bundles the account name *and* the key into one copy-pasteable string. If it lands in a CI log or a chat message, the whole account is compromised rather than just an identifier.

Output the endpoint and the name. Let whatever needs the key fetch it from Key Vault at runtime. This is the same argument as AWS lab 24's ephemeral section.

**Tempting: use `nonsensitive()` to make the output readable.**

```hcl
value = nonsensitive(azurerm_storage_account.data.primary_access_key)
```

This works and strips the protection deliberately. It exists for cases where a value is derived from something sensitive but is provably safe itself — a length, a boolean, a hash.

Using it on the key itself defeats the purpose entirely. If you find yourself reaching for it, check whether you actually need the value in an output at all.

## Verification transcript

```
$ terraform plan
Plan: 3 to add, 0 to change, 0 to destroy.
```

Computed attributes show `(known after apply)`. Outputting `primary_access_key` without `sensitive = true` fails with `Output refers to sensitive values`.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

## Exam connection

**Arguments versus attributes.** You set arguments; the provider computes attributes. Provider-agnostic and directly examinable.

**`(known after apply)`** means the value cannot exist until the resource does.

**Sensitivity is contagious**, and a root output carrying a sensitive value must be marked. The exam asks this about variables you marked; it is equally true of values the provider marked.

**`terraform output -raw`** prints a sensitive value in full, which means `sensitive` is not an access control.
