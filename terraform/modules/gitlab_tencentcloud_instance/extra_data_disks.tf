resource "tencentcloud_cbs_storage" "gitlab_data" {
  count             = var.data_disk_size == null ? 0 : var.node_count
  storage_name      = "${var.prefix}-${var.node_type}-data-${count.index + 1}"
  storage_type      = var.data_disk_type
  storage_size      = var.data_disk_size
  availability_zone = element(var.az_names, count.index)
  encrypt           = false

  tags = {
    gitlab_node_prefix    = var.prefix
    gitlab_node_type      = var.node_type
    gitlab_node_level     = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site       = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role  = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }
}

resource "tencentcloud_cbs_storage_attachment" "gitlab_data_disk_attachment" {
  count       = var.data_disk_size == null ? 0 : var.node_count
  storage_id  = tencentcloud_cbs_storage.gitlab_data[count.index].id
  instance_id = tencentcloud_instance.gitlab[count.index].id
}