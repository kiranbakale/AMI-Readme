resource "azurerm_network_security_group" "haproxy" {
  count = min(var.haproxy_external_node_count, 1)
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
    description = "Allow traffic on TCP ports: HA Stats, Web, SSH, Prometheus and InfluxDB exporter access"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "1936", "80", "443", "2222", "9122", "9090", "5601"]
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type = "haproxy"
  }
}

resource "azurerm_network_security_group" "ssh" {
  name = "${var.prefix}-ssh-default-network-security-group"
  location = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name = "SSH"
    description = "Allow SSH traffic"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }

  tags = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type = "not-haproxy"
  }
}
