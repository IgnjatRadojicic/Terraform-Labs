# Setup: Azure Track (Plan-Only)

## 1. The plan-only rule

**Never run `terraform apply` on an Azure lab.**

This track authenticates against your real Azure subscription. There is no emulator behind it. Every resource in every Azure lab is a real, billable Azure resource, and applying would attempt to create it and charge you.

Every Azure lab is therefore verified entirely from `terraform validate` and `terraform plan` output. No Azure lab has a success criterion that requires an applied resource. If a concept genuinely cannot be checked from a plan, it belongs on the AWS track, and that is where it has been put.

### Why there is no emulator

Azure has no equivalent to LocalStack. [Azurite](https://learn.microsoft.com/azure/storage/common/storage-use-azurite) emulates Azure Storage only, meaning blobs, queues and tables. It does not emulate Azure Resource Manager, which is the API that `azurerm_resource_group`, `azurerm_virtual_network` and essentially everything else speaks to. Plan-only is the honest ceiling for this track, not a temporary workaround waiting on better tooling.

### Check your own account before assuming anything is safe

Account states vary. You may have a free trial with credits, pay-as-you-go with none, or free-tier eligibility on specific resource types. Before starting, check your subscription's status in the [Azure Portal](https://portal.azure.com) under Cost Management.

Even with credits available, keep these labs plan-only. Free-tier eligibility varies by resource type and by region, and the labs are designed so that plan output is sufficient. There is nothing to gain from applying and a real bill to lose.

## 2. What plan-only still teaches you

It is worth being clear that this is not a degraded experience. Plan output confirms a great deal.

| Plan can confirm | Plan cannot confirm |
|---|---|
| Syntax and type correctness | That the resource actually provisions |
| Which resources will be created, and how many | Runtime behaviour or connectivity |
| The resource graph and dependency ordering | Attribute values computed at apply time |
| Variable validation rules firing correctly | Postcondition behaviour after creation |
| `for_each` and `count` producing the right instance keys | Drift, since nothing was ever applied |
| Module wiring and output references resolving | State file contents beyond an empty state |
| `dynamic` blocks generating the right nested blocks | Anything needing `terraform state` subcommands |

The right column is precisely why state and operations labs live on the AWS track.

## 3. Install Azure CLI

Follow the official instructions at [learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli).

| Platform | Command |
|---|---|
| macOS | `brew install azure-cli` |
| Windows | `winget install Microsoft.AzureCLI` |
| Linux | See the distribution-specific instructions on the install page |

Confirm it works:

```bash
az version
```

Note for Windows users: the MSI installer places the CLI under `Program Files` and ignores custom install locations, including winget's `--location` flag. If your system drive is tight, be aware this costs roughly 250 MB there.

## 4. Authenticate

```bash
az login
```

This opens a browser for interactive sign-in. Then confirm which subscription is active, because a wrong subscription is a common cause of confusing plan errors:

```bash
az account show
```

If you have more than one subscription, select the one you intend to use:

```bash
az account list --output table
az account set --subscription "<subscription-id>"
```

The `azurerm` provider picks up these CLI credentials automatically. Never put credentials in configuration files.

## 5. Why authentication is needed at all for plan-only work

This surprises people. If we never apply, why log in?

Because `terraform plan` initialises a real provider client. It needs to resolve the subscription ID, may need to read data sources, and validates certain arguments against the live API. Without credentials, `plan` fails before it produces any output.

Authenticating is free and creates nothing. Signing in does not provision resources and does not cost money. Only `apply` does.

## 6. The mandatory features block

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

That empty `features {}` block is **required**. The `azurerm` provider fails to initialise without it, with an error that does not obviously point at the cause.

It exists because the provider has behaviour toggles, for example whether deleting a resource group should also purge soft-deleted Key Vaults inside it. The block must be present even when you are overriding nothing. If you are coming from AWS, where no such block exists, this is the first thing that will trip you up.

## 7. The resource-group-first model

This is the structural difference from AWS that most justifies the Azure track existing.

In AWS, resources are largely flat. A VPC, an S3 bucket and an IAM role are independent top-level objects sharing no parent container.

In Azure, nearly every resource lives inside a resource group, and that resource group is itself a Terraform resource. Every configuration therefore has a built-in dependency chain:

```hcl
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
```

Most Azure resources need both `resource_group_name` and `location`. Idiomatic configuration pulls both from the resource group rather than repeating string literals, which creates the implicit dependency Terraform uses to order the graph. You can see that ordering in plan output.

## 8. Verify the setup

Create a scratch directory outside this repository, put this in `main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "verify" {
  name     = "rg-terraform-labs-verify"
  location = "West Europe"
}
```

Then:

```bash
terraform init
terraform plan
```

Expected final line:

```
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Stop there. Do not apply.** Seeing that line means the provider initialised, your credentials work, and your configuration is valid. That is the entire goal. Nothing was created, and nothing was billed.

Delete the scratch directory when done.

## 9. If a plan errors on authentication

| Error mentions | Likely cause | Fix |
|---|---|---|
| `Please run 'az login'` | No active session, or it expired | `az login` again |
| `subscription ... not found` | Wrong or no subscription selected | `az account set --subscription "<id>"` |
| `does not have authorization` | Your account lacks permission on that subscription | Check your role assignment in the portal |
| `MissingSubscriptionRegistration` | The resource provider is not registered | `az provider register --namespace Microsoft.Network` (substitute the namespace named in the error) |
| `features` block error | The empty `features {}` block is missing | Add it, see section 6 |

Azure CLI sessions expire. If labs worked yesterday and fail today with an authentication error, `az login` is almost always the answer.
