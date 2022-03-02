resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key_file
}

data "aws_vpc" "selected" {
  id = coalesce(local.vpc_id, local.default_vpc_id)
}

resource "aws_security_group" "gitlab_internal_networking" {
  # Allows for machine internal connections as well as outgoing internet access
  # Avoid changes that cause replacement due to EKS Cluster issue
  name   = "${var.prefix}-internal-networking"
  vpc_id = local.vpc_id

  ingress {
    description = "Open internal networking for VMs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  dynamic "ingress" {
    for_each = range(var.peer_vpc_cidr != null ? 1 : 0)

    content {
      description = "Open internal peer networking for VMs"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [var.peer_vpc_cidr]
    }
  }

  egress {
    description = "Open internet access for VMs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-internal-networking"
  }
}

resource "aws_security_group" "gitlab_external_ssh" {
  name_prefix = "${var.prefix}-external-ssh-"
  vpc_id      = local.vpc_id

  # kics: Terraform AWS - Security groups allow ingress from 0.0.0.0:0, Sensitive Port Is Exposed To Entire Network - False positive, source CIDR is configurable
  # kics-scan ignore-block
  ingress {
    description = "Enable SSH access for VMs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.external_ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-ssh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "gitlab_external_git_ssh" {
  count = min(var.haproxy_external_node_count, 1)

  name_prefix = "${var.prefix}-external-git-ssh-"
  vpc_id      = local.vpc_id

  # kics: Terraform AWS - Security groups allow ingress from 0.0.0.0:0 - False positive, source CIDR is configurable
  # kics-scan ignore-block
  ingress {
    description = "External Git SSH access for ${var.prefix}"
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-git-ssh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# kics: Terraform AWS - Security Group Rules Without Description - False positive due to issue https://github.com/Checkmarx/kics/issues/4691
# kics: Terraform AWS - HTTP Port Open - Context dependent, only allowed on HAProxy External
# kics-scan ignore-block
resource "aws_security_group" "gitlab_external_http_https" {
  count = min(var.haproxy_external_node_count + var.monitor_node_count, 1)

  name_prefix = "${var.prefix}-external-http-https-"
  vpc_id      = local.vpc_id

  ingress {
    description = "Enable HTTP access for select VMs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  ingress {
    description = "Enable HTTPS access for select VMs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  }

  tags = {
    Name = "${var.prefix}-external-http-https"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Not used - To be removed next release
# https://github.com/hashicorp/terraform-provider-aws/issues/2445
resource "aws_security_group" "gitlab_external_monitor" {
  count = min(var.monitor_node_count, 1)

  name_prefix = "${var.prefix}-external-monitor-"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${var.prefix}-external-monitor"
  }

  lifecycle {
    create_before_destroy = true
  }
}
