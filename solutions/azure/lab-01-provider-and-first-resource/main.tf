# Everything in Azure lives inside a RESOURCE GROUP. There is no AWS
# equivalent: an S3 bucket belongs to an account and a region, and that is
# all. An Azure storage account belongs to a resource group, which belongs
# to a subscription.
#
# A resource group is free, it is a real object with a lifecycle, and
# deleting it deletes everything inside it. That last part has no AWS
# analogue and is worth respecting.
resource "azurerm_resource_group" "main" {
  name     = "rg-terraform-labs"
  location = "uksouth"
}

# Storage account naming is far stricter than S3's:
#
#   3 to 24 characters
#   lowercase letters and digits ONLY, no hyphens, no underscores
#   globally unique across all of Azure
#
# "terraform-labs-storage" is a legal bucket name and an illegal storage
# account name. Lab 04 turns this into a validation rule.
resource "azurerm_storage_account" "main" {
  name                = "stterraformlabs001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # These two have no S3 counterpart. S3 has one tier and handles
  # durability for you. Azure makes both explicit.
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
