module "haproxy_external" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "haproxy-external"
  node_count = var.haproxy_external_node_count

  machine_type = var.haproxy_external_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  disk_type = coalesce(var.haproxy_external_disk_type, var.default_disk_type)
  external_ips = var.haproxy_external_external_ips

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  disks = var.haproxy_external_disks

  tags = ["${var.prefix}-web", "${var.prefix}-ssh", "${var.prefix}-haproxy", "${var.prefix}-monitor"]
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "haproxy-internal"
  node_count = var.haproxy_internal_node_count

  machine_type = var.haproxy_internal_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  disk_type = coalesce(var.haproxy_internal_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  disks = var.haproxy_internal_disks

  tags = ["${var.prefix}-haproxy"]
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
