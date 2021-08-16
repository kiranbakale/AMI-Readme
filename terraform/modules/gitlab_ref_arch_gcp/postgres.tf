module "postgres" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "postgres"
  node_count = var.postgres_node_count

  machine_type = var.postgres_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.postgres_disk_size, var.default_disk_size)
  disk_type = coalesce(var.postgres_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  disks = var.postgres_disks
}

output "postgres" {
  value = module.postgres
}
