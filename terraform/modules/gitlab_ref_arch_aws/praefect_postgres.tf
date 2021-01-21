module "praefect_postgres" {
  source = "../gitlab_aws_instance"

  prefix = var.prefix
  node_type = "praefect_postgres"
  node_count = var.praefect_postgres_node_count

  instance_type = var.praefect_postgres_instance_type
  ami_id = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size = coalesce(var.praefect_postgres_disk_size, var.default_disk_size)
  disk_type = coalesce(var.praefect_postgres_disk_type, var.default_disk_type)

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "praefect_postgres" {
  value = module.praefect_postgres
}