resource "alicloud_vswitch" "vswitches" {
  vpc_id       = alicloud_vpc.vpc.id
  cidr_block   = var.k8s_vswitch_cidr
  zone_id      = data.alicloud_zones.zones_ds.zones[0].id
  vswitch_name = "${var.prefix}-k8s-vswitch"
}

resource "alicloud_nat_gateway" "default" {
  vpc_id = alicloud_vpc.vpc.id
  name   = var.prefix
}

resource "alicloud_eip" "default" {
  bandwidth = 10
}

resource "alicloud_eip_association" "default" {
  allocation_id = alicloud_eip.default.id
  instance_id   = alicloud_nat_gateway.default.id
}

resource "alicloud_snat_entry" "default" {
  snat_table_id     = alicloud_nat_gateway.default.snat_table_ids
  source_vswitch_id = alicloud_vswitch.vswitches.id
  snat_ip           = alicloud_eip.default.ip_address
}

resource "alicloud_cs_managed_kubernetes" "k8s" {
  name                  = "${var.prefix}-k8s"
  worker_vswitch_ids    = alicloud_vswitch.vswitches.*.id
  new_nat_gateway       = true
  worker_instance_types = [var.worker_instance_type]
  worker_number         = var.k8s_worker_number
  worker_disk_category  = var.worker_disk_category
  worker_disk_size      = var.worker_disk_size
  password              = var.ecs_password
  pod_cidr              = var.k8s_pod_cidr
  service_cidr          = var.k8s_service_cidr
  enable_ssh            = true
  install_cloud_monitor = true
  depends_on            = [alicloud_snat_entry.default]
}
