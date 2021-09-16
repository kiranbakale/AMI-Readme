module "consul" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "consul"
  node_count = var.consul_node_count

  machine_type  = var.consul_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.consul_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.consul_disk_type, var.default_disk_type)

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
  disks          = var.consul_disks

  setup_external_ip = var.setup_external_ips
}

output "consul" {
  value = module.consul
}
