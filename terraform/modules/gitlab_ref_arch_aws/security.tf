resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key_file
}

resource "aws_security_group" "gitlab_internal_networking" {
  # Allows for machine internal connections as well as outgoing internet access
  name = "${var.prefix}-internal-networking"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-internal-networking"
  }
}

resource "aws_security_group" "gitlab_external_ssh" {
  name = "${var.prefix}-external-ssh"
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
  name = "${var.prefix}-external-git-ssh"
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
  name = "${var.prefix}-external-http-https"
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

resource "aws_security_group" "gitlab_external_haproxy_stats" {
  name = "${var.prefix}-external-haproxy-stats"
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
  name = "${var.prefix}-external-monitor"
  ingress {
    from_port   = 9122
    to_port     = 9122
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-external-monitor"
  }
}
