resource "azurerm_virtual_network" "gitlab" {
  name                = "${var.prefix}-default-network"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "gitlab" {
  name                 = "${var.prefix}-internal-subnet"
  virtual_network_name = azurerm_virtual_network.gitlab.name
  address_prefixes     = var.subnet_address_ranges
  resource_group_name  = var.resource_group_name
}
