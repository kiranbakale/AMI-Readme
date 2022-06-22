module "gitlab_rails" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "gitlab-rails"
  node_count      = var.gitlab_rails_node_count
  additional_tags = var.additional_tags

  instance_type              = var.gitlab_rails_instance_type
  ami_id                     = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_18_04[0].id
  disk_size                  = coalesce(var.gitlab_rails_disk_size, var.default_disk_size)
  disk_type                  = coalesce(var.gitlab_rails_disk_type, var.default_disk_type)
  disk_encrypt               = coalesce(var.gitlab_rails_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn           = var.gitlab_rails_disk_kms_key_arn != null ? var.gitlab_rails_disk_kms_key_arn : var.default_kms_key_arn
  disk_delete_on_termination = var.gitlab_rails_disk_delete_on_termination != null ? var.gitlab_rails_disk_delete_on_termination : var.default_disk_delete_on_termination
  data_disks                 = var.gitlab_rails_data_disks
  subnet_ids                 = local.backend_subnet_ids

  iam_instance_policy_arns = flatten([
    local.gitlab_s3_policy_arns,
    var.default_iam_instance_policy_arns,
    var.gitlab_rails_iam_instance_policy_arns
  ])
  iam_permissions_boundary_arn = var.default_iam_permissions_boundary_arn

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
