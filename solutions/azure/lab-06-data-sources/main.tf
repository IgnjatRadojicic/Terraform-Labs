# A DATA SOURCE reads something that already exists. Terraform does not
# own it, will not change it, and will not destroy it.
#
# azurerm_client_config is the closest equivalent to aws_caller_identity:
# it tells you which subscription and tenant you are authenticated
# against. Azure exposes more than AWS does here, because the
# subscription/tenant split has no AWS counterpart.
data "azurerm_client_config" "current" {}

# A RESOURCE is something Terraform creates and owns.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                = "st${var.project_name}data"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    # Using data from a data source is how you avoid hardcoding
    # environment-specific values that differ per subscription.
    Subscription = data.azurerm_client_config.current.subscription_id
  }
}
