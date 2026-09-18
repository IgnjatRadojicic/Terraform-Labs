resource "azurerm_resource_group" "main" {
  name     = "rg-validation-${var.environment}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = var.replication_type
}
