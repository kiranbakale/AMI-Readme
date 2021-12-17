resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key_file
}

data "aws_vpc" "selected" {
  id = coalesce(local.vpc_id, local.default_vpc_id)
}

resource "aws_security_group" "gitlab_internal_networking" {
  # Allows for machine internal connections as well as outgoing internet access
  name   = "${var.prefix}-internal-networking"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
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
  name   = "${var.prefix}-external-ssh"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-ssh"
  }
}

resource "aws_security_group" "gitlab_external_git_ssh" {
  count  = min(var.haproxy_external_node_count, 1)
  name   = "${var.prefix}-external-git-ssh"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-git-ssh"
  }
}

resource "aws_security_group" "gitlab_external_http_https" {
  count  = min(var.haproxy_external_node_count + var.monitor_node_count, 1)
  name   = "${var.prefix}-external-http-https"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-http-https"
  }
}

# https://github.com/hashicorp/terraform/issues/8617
# To be investigated
resource "aws_security_group" "gitlab_external_haproxy_stats" {
  count  = min(var.haproxy_external_node_count + var.haproxy_internal_node_count, 1)
  name   = "${var.prefix}-external-haproxy-stats"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 1936
    to_port     = 1936
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-haproxy-stats"
  }
}

resource "aws_security_group" "gitlab_external_monitor" {
  count  = min(var.monitor_node_count, 1)
  name   = "${var.prefix}-external-monitor"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 9122
    to_port     = 9122
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-monitor"
  }
}
