module "haproxy_external" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "haproxy-external"
  node_count      = var.haproxy_external_node_count
  additional_tags = var.additional_tags

  instance_type              = var.haproxy_external_instance_type
  ami_id                     = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_18_04[0].id
  disk_size                  = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  disk_type                  = coalesce(var.haproxy_external_disk_type, var.default_disk_type)
  disk_encrypt               = coalesce(var.haproxy_external_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn           = var.haproxy_external_disk_kms_key_arn != null ? var.haproxy_external_disk_kms_key_arn : var.default_kms_key_arn
  disk_delete_on_termination = var.haproxy_external_disk_delete_on_termination != null ? var.haproxy_external_disk_delete_on_termination : var.default_disk_delete_on_termination
  data_disks                 = var.haproxy_external_data_disks

  iam_instance_policy_arns = flatten([
    var.default_iam_instance_policy_arns,
    var.haproxy_external_iam_instance_policy_arns
  ])

  # Select Public subnets if configured first as this node is external
  subnet_ids                = local.frontend_subnet_ids
  elastic_ip_allocation_ids = var.haproxy_external_elastic_ip_allocation_ids

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id,
    try(aws_security_group.gitlab_external_git_ssh[0].id, null),
    try(aws_security_group.gitlab_external_http_https[0].id, null)
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "haproxy-internal"
  node_count      = var.haproxy_internal_node_count
  additional_tags = var.additional_tags

  instance_type              = var.haproxy_internal_instance_type
  ami_id                     = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_18_04[0].id
  disk_size                  = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  disk_type                  = coalesce(var.haproxy_internal_disk_type, var.default_disk_type)
  disk_encrypt               = coalesce(var.haproxy_internal_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn           = var.haproxy_internal_disk_kms_key_arn != null ? var.haproxy_internal_disk_kms_key_arn : var.default_kms_key_arn
  disk_delete_on_termination = var.haproxy_internal_disk_delete_on_termination != null ? var.haproxy_internal_disk_delete_on_termination : var.default_disk_delete_on_termination
  data_disks                 = var.haproxy_internal_data_disks
  subnet_ids                 = local.backend_subnet_ids

  iam_instance_policy_arns = flatten([
    var.default_iam_instance_policy_arns,
    var.haproxy_internal_iam_instance_policy_arns
  ])

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
