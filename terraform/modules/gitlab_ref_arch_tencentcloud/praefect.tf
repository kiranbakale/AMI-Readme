module "praefect" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "praefect"
  node_count = var.praefect_node_count

  instance_type = var.praefect_instance_type
  disk_size     = coalesce(var.praefect_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.praefect_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "praefect" {
  value = module.praefect
}
