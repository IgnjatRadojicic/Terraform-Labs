# Solution: Azure Lab 07, Resource dependencies

Pairs with **AWS lab 07**.

## AWS vs Azure at a glance

| | AWS | Azure |
|---|---|---|
| Chain depth | bucket → object (2) | **RG → account → container → blob (4)** |
| Argument style | consistently ARNs or names | **mixed: container takes an ID, blob takes a name** |
| `depends_on` needed | no | no |

## Walkthrough

### Four links, all implicit

```hcl
resource "azurerm_storage_container" "uploads" {
  storage_account_id = azurerm_storage_account.main.id        # edge
}

resource "azurerm_storage_blob" "config" {
  storage_account_name   = azurerm_storage_account.main.name  # edge
  storage_container_name = azurerm_storage_container.uploads.name
}
```

Every reference to another resource's attribute **is** the dependency. There is nothing else to write, and no `depends_on` appears anywhere in this lab.

Azure's deeper chain makes the graph easier to read than AWS's, which is the main reason this lab is worth repeating rather than skipping.

### The argument inconsistency

Step 7 asked you to notice this:

```hcl
storage_account_id   = azurerm_storage_account.main.id      # container wants an ID
storage_account_name = azurerm_storage_account.main.name    # blob wants a name
```

Both are correct for azurerm 4.x. The container moved to `storage_account_id` in version 4; the blob still takes a name.

There is no principle here to learn, only a habit: **read the resource page rather than pattern-matching from the resource above it.** Assuming consistency across a provider's resources is a reliable way to lose twenty minutes, and azurerm is less consistent than the AWS provider because it has absorbed more API generations.

### What a hardcoded string breaks

Step 5 had you replace a reference with an equal literal:

```hcl
storage_account_id = "/subscriptions/.../storageAccounts/stpipelinedata"
```

The plan still succeeds and the value is identical. What you lost is the **edge in the graph**.

Terraform no longer knows the container depends on the account, so it is free to schedule them in any order, or in parallel. It may work every single time you test it and fail under different timing, different resource counts, or a different provider version.

**A correct plan is not evidence of a correct graph.** The AWS lab made this point with an empty `version_id`; here it is the same lesson with a clearer graph to look at.

`terraform graph` is how you check. On Windows, redirect it to a file rather than reading it in the terminal, since the output is wide.

## Why not the alternative

**Tempting: add `depends_on` to be safe.**

```hcl
resource "azurerm_storage_container" "uploads" {
  storage_account_id = azurerm_storage_account.main.id
  depends_on         = [azurerm_storage_account.main]     # redundant
}
```

The reference already created that edge. The `depends_on` adds nothing, and it teaches the next reader that references are insufficient — so they start adding it everywhere, and now the graph is cluttered with hand-maintained edges that can drift from reality.

`depends_on` is for dependencies Terraform **cannot see**: an IAM role assignment that must exist before a resource can use it, where the connection is enforced by the cloud rather than expressed in the configuration. Lab 15 has a genuine example.

**Tempting: use the blob's `source` argument with a local file.**

```hcl
source = "app.conf"
```

Fine in real use, awkward in a lab because it requires a file on disk and makes the configuration non-portable. `source_content` keeps the lab self-contained.

## Verification transcript

```
$ terraform plan
Plan: 4 to add, 0 to change, 0 to destroy.
```

Resource group, storage account, container, blob. `terraform graph` shows the unbroken chain, and no `depends_on` appears anywhere in the configuration.

Verified against a real subscription with Terraform 1.16.0 and azurerm 4.81.0, plan only.

## Exam connection

**Implicit dependencies come from references.** This is the default and the correct answer to most ordering questions.

**`depends_on` is for dependencies Terraform cannot infer**, and overusing it is a documented anti-pattern.

**`terraform graph`** outputs DOT format describing the dependency graph.

**Terraform parallelises independent resources** — ten by default. That parallelism is exactly what a missing edge exposes you to, which is why the hardcoded-string version is dangerous rather than merely untidy.
