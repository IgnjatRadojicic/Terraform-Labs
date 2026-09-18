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

# for_each identifies instances by KEY, not position. Keys do not shift
# when a neighbour is removed, which is the entire difference from Lab 08.
#
# for_each accepts a map or a set of strings, never a list. toset()
# performs the conversion, discarding order and duplicates.
resource "azurerm_storage_container" "zone" {
  for_each = toset(var.zones)

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "zone" {
  for_each = toset(var.zones)

  # With a set, each.key and each.value are the same thing, because a set
  # has no keys of its own so Terraform uses the element itself.
  name                = "log-${var.project_name}-${each.value}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku               = "PerGB2018"
  retention_in_days = 30
}
