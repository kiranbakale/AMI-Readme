module "gitlab_nfs" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "gitlab-nfs"
  node_count = var.gitlab_nfs_node_count

  machine_type = var.gitlab_nfs_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  disk_type = coalesce(var.gitlab_nfs_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  disks = var.gitlab_nfs_disks

  setup_external_ip = var.setup_external_ips
}

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
