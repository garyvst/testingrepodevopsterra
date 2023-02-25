resource "azurerm_resource_group" "rgstg" {
  name     = "atsaksrg1975"
  location = "US central"
}

resource "azurerm_storage_account" "stg" {
  name                     = "atsaksstg1975"
  resource_group_name      = azurerm_resource_group.rgstg.name
  location                 = azurerm_resource_group.rgstg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "Blob" {
  name                  = "atsakscn1975"
  storage_account_name  = azurerm_storage_account.stg.name
  container_access_type = "private"
}