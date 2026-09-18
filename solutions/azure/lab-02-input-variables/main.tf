resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
  tags     = var.tags
}

# Note the name expression. Storage account names allow no hyphens, so
# the usual "${var.project_name}-uploads" pattern from the AWS track is
# illegal here and must be concatenated without a separator.
resource "azurerm_storage_account" "uploads" {
  name                = "st${var.project_name}uploads"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Blob versioning lives in a nested block on the storage account
  # itself, rather than in a separate resource as with S3.
  blob_properties {
    versioning_enabled = var.enable_versioning
  }

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku               = "PerGB2018"
  retention_in_days = var.retention_days

  tags = var.tags
}
