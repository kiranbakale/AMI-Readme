module "elastic" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "elastic"
  node_count = var.elastic_node_count

  machine_type = var.elastic_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.elastic_disk_size, var.default_disk_size)
  disk_type = coalesce(var.elastic_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true

  disks = var.elastic_disks

  setup_external_ip = var.setup_external_ips
}

output "elastic" {
  value = module.elastic
}
