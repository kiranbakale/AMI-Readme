resource "azurerm_storage_container" "gitlab_object_storage" {
  name = "${var.prefix}-object-storage"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}
