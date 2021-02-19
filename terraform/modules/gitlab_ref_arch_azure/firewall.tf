resource "azurerm_network_security_group" "haproxy" {
  name = "${var.prefix}-haproxy-network-security-group"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "icmp"
    description = "Allow Icmp"
    priority = 1002
    direction = "Inbound"
    access = "Allow"
    protocol = "Icmp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name = "tcp"
    description = "Allow traffic on TCP ports: HA Stats, Web, SSH, Prometheus and InfluxDB access"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "1936", "80", "443", "2222", "8086", "9090", "5601"]
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type = "haproxy"
  }
}
