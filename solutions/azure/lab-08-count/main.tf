resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                = "st${var.project_name}lake"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# count takes a NUMBER. count.index is the current iteration, from 0.
#
# Azure needs more scaffolding than AWS here: the resource group and
# storage account are created once, and only the containers repeat. In
# the AWS track the buckets themselves repeated, because S3 has no
# equivalent grouping layer.
resource "azurerm_storage_container" "zone" {
  count = length(var.zones)

  name                  = var.zones[count.index]
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "zone" {
  count = length(var.zones)

  name                = "log-${var.project_name}-${var.zones[count.index]}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku               = "PerGB2018"
  retention_in_days = 30
}
