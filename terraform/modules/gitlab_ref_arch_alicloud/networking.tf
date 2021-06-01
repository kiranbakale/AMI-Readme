data "alicloud_instance_types" "instance_type" {
  instance_type_family = var.instance_type_family
  cpu_core_count       = var.default_cpu_core_count
  memory_size          = var.default_memory_size
}

data "alicloud_zones" "zones_ds" {
  available_instance_type = data.alicloud_instance_types.instance_type.instance_types[0].id
}

resource "alicloud_vpc" "vpc" {
  cidr_block = var.vpc_cidr
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id     = alicloud_vpc.vpc.id
  cidr_block = var.vswitch_cidr
  zone_id    = data.alicloud_zones.zones_ds.zones[0].id
}

resource "alicloud_security_group" "gitlab_external_ssh" {
  name                = "${var.prefix}-external-ssh-networking"
  description         = "${var.prefix}-external-ssh-networking group"
  vpc_id              = alicloud_vpc.vpc.id
  inner_access_policy = "Accept"
}
