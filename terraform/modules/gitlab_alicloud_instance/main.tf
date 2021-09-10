terraform {
  required_version = ">= 0.14"
}

resource "alicloud_instance" "gitlab" {
  count                = var.node_count
  instance_type        = var.instance_type
  image_id             = var.image_id
  system_disk_category = var.disk_type
  system_disk_size     = var.disk_size

  security_groups = var.security_group_ids
  vswitch_id      = var.vswitch_id

  instance_name = "${var.prefix}-${var.node_type}-${count.index + 1}"
  host_name     = "${var.prefix}-${var.node_type}-${count.index + 1}"

  internet_max_bandwidth_out = 100

  key_name = var.ssh_key_name

  tags = {
    gitlab_node_prefix    = var.prefix
    gitlab_node_type      = var.node_type
    gitlab_node_level     = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site       = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role  = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }
}
