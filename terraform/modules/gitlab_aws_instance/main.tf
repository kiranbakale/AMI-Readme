terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
}

resource "aws_instance" "gitlab" {
  count                  = var.node_count
  instance_type          = var.instance_type
  ami                    = var.ami_id
  key_name               = var.ssh_key_name
  vpc_security_group_ids = compact(var.security_group_ids)
  iam_instance_profile   = length(var.iam_instance_policy_arns) > 0 ? aws_iam_instance_profile.gitlab[0].name : null

  subnet_id = var.subnet_ids != null ? element(tolist(var.subnet_ids), count.index) : null

  root_block_device {
    volume_type = var.disk_type
    volume_size = var.disk_size
    iops        = var.disk_iops

    encrypted  = var.disk_encrypt
    kms_key_id = var.disk_kms_key_arn
  }

  tags = merge({
    Name                  = "${var.prefix}-${var.node_type}-${count.index + 1}"
    gitlab_node_prefix    = var.prefix
    gitlab_node_type      = var.node_type
    gitlab_node_level     = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site       = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role  = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }, var.additional_tags)

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

# Data Disks
locals {
  node_data_disks = flatten([
    for i in range(var.node_count) :
    [
      for data_disk in var.data_disks : {
        name              = data_disk.name
        num               = index(var.data_disks, data_disk)
        type              = lookup(data_disk, "type", var.disk_type)
        size              = lookup(data_disk, "size", var.disk_size)
        iops              = lookup(data_disk, "iops", null)
        device_name       = data_disk.device_name
        availability_zone = aws_instance.gitlab[i].availability_zone
        instance_id       = aws_instance.gitlab[i].id
        instance_name     = aws_instance.gitlab[i].tags_all["Name"]
        instance_num      = i
        instance_disk_num = index(var.data_disks, data_disk)
      }
      if data_disk.name != null
    ]
  ])
}

resource "aws_ebs_volume" "gitlab" {
  for_each = { for d in local.node_data_disks : "${d.instance_name}-${d.name}" => d }

  type              = each.value.type
  size              = each.value.size
  iops              = each.value.iops
  availability_zone = each.value.availability_zone

  encrypted  = true
  kms_key_id = var.disk_kms_key_arn

  tags = {
    Name = each.key
  }
}

resource "aws_volume_attachment" "gitlab" {
  for_each = { for d in local.node_data_disks : "${d.instance_name}-${d.name}" => d }

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.gitlab[each.key].id
  instance_id = each.value.instance_id
}

resource "aws_eip_association" "gitlab" {
  count = length(var.elastic_ip_allocation_ids)

  instance_id   = aws_instance.gitlab[count.index].id
  allocation_id = var.elastic_ip_allocation_ids[count.index]
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "gitlab" {
  count = var.node_count > 0 && length(var.iam_instance_policy_arns) > 0 ? 1 : 0
  name  = "${var.prefix}-${var.node_type}-profile"
  role  = aws_iam_role.gitlab[0].name
}

resource "aws_iam_role" "gitlab" {
  count = var.node_count > 0 && length(var.iam_instance_policy_arns) > 0 ? 1 : 0
  name  = "${var.prefix}-${var.node_type}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gitlab" {
  count = var.node_count > 0 ? length(var.iam_instance_policy_arns) : 0

  role       = aws_iam_role.gitlab[0].name
  policy_arn = var.iam_instance_policy_arns[count.index]
}
