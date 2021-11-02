module "consul" {
  source = "../gitlab_aws_instance"

  prefix     = var.prefix
  node_type  = "consul"
  node_count = var.consul_node_count

  instance_type    = var.consul_instance_type
  ami_id           = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size        = coalesce(var.consul_disk_size, var.default_disk_size)
  disk_type        = coalesce(var.consul_disk_type, var.default_disk_type)
  disk_encrypt     = coalesce(var.consul_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn = var.consul_disk_kms_key_arn != null ? var.consul_disk_kms_key_arn : var.default_kms_key_arn
  data_disks       = var.consul_data_disks
  subnet_ids       = local.subnet_ids

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "consul" {
  value = module.consul
}
