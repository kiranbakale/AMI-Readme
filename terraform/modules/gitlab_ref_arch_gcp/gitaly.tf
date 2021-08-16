module "gitaly" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "gitaly"
  node_count = var.gitaly_node_count

  machine_type = var.gitaly_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.gitaly_disk_size, var.default_disk_size)
  disk_type = coalesce(var.gitaly_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
  disks = var.gitaly_disks
}

output "gitaly" {
  value = module.gitaly
}
