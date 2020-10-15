module "haproxy_external" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "haproxy-external"
  node_count = 1
  
  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_F2s_v2"
  external_ip_ids = ["${data.azurerm_public_ip.haproxy_external_ip.id}"]

  network_security_group = azurerm_network_security_group.haproxy
}

data "azurerm_public_ip" "haproxy_external_ip" {
  name                = var.external_ip_name
  resource_group_name = var.resource_group_name
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "haproxy-internal"
  node_count = 1
  
  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_F2s_v2"
}

output "haproxy_internal" {
  value = module.haproxy_internal
}

resource "azurerm_network_security_group" "haproxy" {
    name                = "${var.prefix}-haproxy-network-security-group"
    location            = var.location
    resource_group_name = var.resource_group_name
    
    security_rule {
        name                       = "icmp"
        description                = "Allow Icmp"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Icmp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "tcp"
        description                = "Allow traffic on TCP ports: HA Stats, Web, SSH, Prometheus and InfluxDB access"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22", "1936", "80", "443", "2222", "8086", "9090", "5601"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
      gitlab_node_prefix = var.prefix
      gitlab_node_type = "haproxy"
    }
}
