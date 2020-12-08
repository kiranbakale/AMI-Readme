module "pgbouncer" {
  source = "../gitlab_aws_instance"

  prefix = var.prefix
  node_type = "pgbouncer"
  node_count = var.pgbouncer_node_count

  instance_type = var.pgbouncer_instance_type
  ami_id = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size = coalesce(var.pgbouncer_disk_size, var.default_disk_size)
  disk_type = coalesce(var.pgbouncer_disk_type, var.default_disk_type)
  iam_instance_profile = aws_iam_instance_profile.gitlab_s3_profile.name

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "pgbouncer" {
  value = module.pgbouncer
}