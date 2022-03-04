module "elastic" {
  source = "../gitlab_aws_instance"

  prefix          = var.prefix
  node_type       = "elastic"
  node_count      = var.elastic_node_count
  additional_tags = var.additional_tags

  instance_type    = var.elastic_instance_type
  ami_id           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_18_04[0].id
  disk_size        = coalesce(var.elastic_disk_size, var.default_disk_size)
  disk_type        = coalesce(var.elastic_disk_type, var.default_disk_type)
  disk_encrypt     = coalesce(var.elastic_disk_encrypt, var.default_disk_encrypt)
  disk_kms_key_arn = var.elastic_disk_kms_key_arn != null ? var.elastic_disk_kms_key_arn : var.default_kms_key_arn
  data_disks       = var.elastic_data_disks
  subnet_ids       = local.backend_subnet_ids

  iam_instance_policy_arns = flatten([
    var.default_iam_instance_policy_arns,
    var.elastic_iam_instance_policy_arns
  ])

  ssh_key_name = aws_key_pair.ssh_key.key_name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id,
    aws_security_group.gitlab_external_ssh.id
  ]

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "elastic" {
  value = module.elastic
}
