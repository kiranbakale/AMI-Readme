module "haproxy_external" {
  source = "../gitlab_aws_instance"

  prefix = var.prefix
  node_type = "haproxy-external"
  node_count = var.haproxy_external_node_count

  instance_type = var.haproxy_external_instance_type
  ami_id = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  disk_type = coalesce(var.haproxy_external_disk_type, var.default_disk_type)
  iam_instance_profile = aws_iam_instance_profile.gitlab_s3_profile.name
  elastic_ip_allocation_ids = var.haproxy_external_elastic_ip_allocation_ids

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id,
    aws_security_group.gitlab_external_git_ssh.id,
    aws_security_group.gitlab_external_http_https.id,
    aws_security_group.gitlab_external_haproxy_stats.id,
  ]

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_aws_instance"

  prefix = var.prefix
  node_type = "haproxy-internal"
  node_count = var.haproxy_internal_node_count

  instance_type = var.haproxy_internal_instance_type
  ami_id = coalesce(var.ami_id, data.aws_ami.ubuntu_18_04.id)
  disk_size = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  disk_type = coalesce(var.haproxy_internal_disk_type, var.default_disk_type)

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_internal" {
  value = module.haproxy_internal
}