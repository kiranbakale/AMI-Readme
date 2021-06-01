module "gitlab_nfs" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "gitlab-nfs"
  node_count = var.gitlab_nfs_node_count

  instance_type = var.gitlab_nfs_instance_type
  disk_size     = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.gitlab_nfs_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
