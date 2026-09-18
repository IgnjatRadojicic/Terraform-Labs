# Azure's dependency chain is one link longer than AWS's. An S3 object
# needs a bucket. An Azure blob needs a container, which needs a storage
# account, which needs a resource group.
#
# Every arrow below is IMPLICIT, created by one resource referencing
# another's attribute. None of it needs depends_on.
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  # This reference is the dependency. Terraform cannot know the resource
  # group's name until it exists, so it must create it first.
  name                = "st${var.project_name}data"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "config" {
  name                   = "app.conf"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.uploads.name
  type                   = "Block"
  source_content         = "environment=dev"
}
