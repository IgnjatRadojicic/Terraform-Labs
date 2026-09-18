resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                = "st${var.project_name}main"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# With a MAP, each.key is the map key and each.value is the object behind
# it. That is what lets every instance carry different configuration,
# which a set cannot express.
#
# Note that container names permit hyphens, unlike storage account names.
# Azure's naming rules differ per resource type, which is a recurring
# annoyance worth internalising early.
resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = each.value.access_type
}

resource "azurerm_log_analytics_workspace" "this" {
  for_each = var.containers

  name                = "log-${var.project_name}-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku               = "PerGB2018"
  retention_in_days = each.value.retention_days
}

# Only the audited entries get a dedicated archive container. Filter the
# map rather than creating one for everything and leaving it unused.
#
# The filter is an ordinary for expression with an if clause, and its
# result is still a map, so it is still a valid for_each argument.
resource "azurerm_storage_container" "audit" {
  for_each = { for k, v in var.containers : k => v if v.audited }

  name                  = "${each.key}-audit"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}
