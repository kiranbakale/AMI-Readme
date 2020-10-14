resource "azurerm_virtual_network" "gitlab" {
  name                = "${var.prefix}-default-network"
  address_space       = ["172.17.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "gitlab" {
  name                 = "${var.prefix}-internal-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.gitlab.name
  address_prefixes     = ["172.17.0.0/16"]
}

output "subnet" {
  value = azurerm_subnet.gitlab
}
