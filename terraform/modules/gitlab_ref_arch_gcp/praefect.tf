module "praefect" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "praefect"
  node_count = var.praefect_node_count

  machine_type = var.praefect_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.praefect_disk_size, var.default_disk_size)
  disk_type = coalesce(var.praefect_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
  disks = var.praefect_disks

  setup_external_ip = var.setup_external_ips
}

output "praefect" {
  value = module.praefect
}
