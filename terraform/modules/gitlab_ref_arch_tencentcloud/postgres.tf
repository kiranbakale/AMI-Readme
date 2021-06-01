module "postgres" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "postgres"
  node_count = var.postgres_node_count

  instance_type = var.postgres_instance_type
  disk_size     = coalesce(var.postgres_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.postgres_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "postgres" {
  value = module.postgres
}
