module "gitlab_nfs" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "gitlab-nfs"
  node_count      = var.gitlab_nfs_node_count
  additional_tags = var.additional_tags

  instance_type    = var.gitlab_nfs_instance_type
  ami_id           = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size        = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  disk_type        = coalesce(var.gitlab_nfs_disk_type, var.default_disk_type)
  disk_encrypt     = coalesce(var.gitlab_nfs_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn = var.gitlab_nfs_disk_kms_key_arn != null ? var.gitlab_nfs_disk_kms_key_arn : var.default_kms_key_arn
  data_disks       = var.gitlab_nfs_data_disks
  subnet_ids       = local.backend_subnet_ids

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
