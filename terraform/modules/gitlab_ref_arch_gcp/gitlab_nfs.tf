module "gitlab_nfs" {
  source = "../gitlab_gcp_instance"

  prefix            = var.prefix
  node_type         = "gitlab-nfs"
  node_count        = var.gitlab_nfs_node_count
  additional_labels = var.additional_labels

  machine_type  = var.gitlab_nfs_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.gitlab_nfs_disk_type, var.default_disk_type)
  disks         = var.gitlab_nfs_disks

  vpc               = local.vpc_name
  subnet            = local.subnet_name
  zones             = var.zones
  setup_external_ip = var.setup_external_ips

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  allow_stopping_for_update = var.allow_stopping_for_update
}

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
