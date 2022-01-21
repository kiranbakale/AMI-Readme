resource "azurerm_network_security_group" "haproxy" {
  count               = min(var.haproxy_external_node_count, 1)
  name                = "${var.prefix}-haproxy-network-security-group"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "haproxy"
  }
}

resource "azurerm_network_security_rule" "icmp_rule" {
  count                       = min(var.haproxy_external_node_count, 1)
  name                        = "icmp_rule"
  description                 = "Allow ICMP"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = coalescelist(var.icmp_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.haproxy[0].name
}

resource "azurerm_network_security_rule" "http_rule" {
  count                       = min(var.haproxy_external_node_count, 1)
  name                        = "http_rule"
  description                 = "Allow Web traffic"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefixes     = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.haproxy[0].name
}

resource "azurerm_network_security_rule" "ssh_rule" {
  count                       = min(var.haproxy_external_node_count, 1)
  name                        = "ssh_rule"
  description                 = "Allow Git SSH traffic"
  priority                    = 1005
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["2222"]
  source_address_prefixes     = coalescelist(var.ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.haproxy[0].name
}

resource "azurerm_network_security_rule" "external_ssh_rule" {
  count                       = min(var.haproxy_external_node_count, 1)
  name                        = "external_ssh_rule"
  description                 = "Allow SSH traffic"
  priority                    = 1006
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22"]
  source_address_prefixes     = coalescelist(var.external_ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.haproxy[0].name
}

resource "azurerm_network_security_rule" "monitor_rule" {
  count                       = min(var.haproxy_external_node_count, 1)
  name                        = "monitor_rule"
  description                 = "Allow Monitor traffic for InfluxDB exporter access"
  priority                    = 1007
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["9122"]
  source_address_prefixes     = coalescelist(var.monitor_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.haproxy[0].name
}

resource "azurerm_network_security_group" "ssh" {
  name                = "${var.prefix}-ssh-default-network-security-group"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    description                = "Allow SSH traffic"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = coalescelist(var.ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
    destination_address_prefix = "*"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "not-haproxy"
  }
}
