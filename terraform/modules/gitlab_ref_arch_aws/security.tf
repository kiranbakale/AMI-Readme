resource "aws_key_pair" "ssh_key" {
  count = var.ssh_public_key != null || var.ssh_public_key_file != null ? 1 : 0

  key_name   = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key != null ? var.ssh_public_key : var.ssh_public_key_file
}

data "aws_vpc" "selected" {
  id = coalesce(local.vpc_id, local.default_vpc_id)
}

resource "aws_security_group" "gitlab_internal_networking" {
  # Allows for machine internal connections as well as outgoing internet access
  # Avoid changes that cause replacement due to EKS Cluster issue
  name   = "${var.prefix}-internal-networking"
  vpc_id = data.aws_vpc.selected.id

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
  count = var.ssh_public_key != null || var.ssh_public_key_file != null ? 1 : 0

  name_prefix = "${var.prefix}-external-ssh-"
  vpc_id      = data.aws_vpc.selected.id

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
  vpc_id      = data.aws_vpc.selected.id

  # kics: Terraform AWS - Security groups allow ingress from 0.0.0.0:0 - False positive, source CIDR is configurable
  # kics-scan ignore-block
  ingress {
    description = "External Git SSH access for ${var.prefix}"
    from_port   = var.external_ssh_port
    to_port     = var.external_ssh_port
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
  vpc_id      = data.aws_vpc.selected.id

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

# Services Security Groups
## AWS RDS
### GitLab
resource "aws_security_group" "gitlab_rds" {
  count = local.rds_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_rds" {
  count = local.rds_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds[0].id

  type        = "ingress"
  description = "Enable internal access to RDS"
  from_port   = var.rds_postgres_port
  to_port     = var.rds_postgres_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.rds_postgres_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

### Praefect
resource "aws_security_group" "gitlab_rds_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-praefect-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds-praefect"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_rds_praefect" {
  count = local.rds_praefect_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds_praefect[0].id

  type        = "ingress"
  description = "Enable internal access to Praefect RDS"
  from_port   = var.rds_praefect_postgres_port
  to_port     = var.rds_praefect_postgres_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.rds_praefect_postgres_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

### Geo Tracking
resource "aws_security_group" "gitlab_rds_geo_tracking" {
  count = local.rds_geo_tracking_postgres_create ? 1 : 0

  name_prefix = "${var.prefix}-rds-geo-tracking-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-rds-geo-tracking"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_rds_geo_tracking" {
  count = local.rds_geo_tracking_postgres_create ? 1 : 0

  security_group_id = aws_security_group.gitlab_rds_geo_tracking[0].id

  type        = "ingress"
  description = "Enable internal access to Geo Tracking RDS"
  from_port   = var.rds_geo_tracking_postgres_port
  to_port     = var.rds_geo_tracking_postgres_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.rds_geo_tracking_postgres_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

## AWS Elasticache
### Redis (Combined)
resource "aws_security_group" "gitlab_elasticache_redis" {
  count = min(var.elasticache_redis_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_elasticache_redis" {
  count = min(var.elasticache_redis_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis[0].id

  type        = "ingress"
  description = "Enable internal access to ElastiCache Redis"
  from_port   = var.elasticache_redis_port
  to_port     = var.elasticache_redis_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.elasticache_redis_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

### Redis Cache
resource "aws_security_group" "gitlab_elasticache_redis_cache" {
  count = min(var.elasticache_redis_cache_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-cache-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-cache"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_elasticache_redis_cache" {
  count = min(var.elasticache_redis_cache_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis_cache[0].id

  type        = "ingress"
  description = "Enable internal access to ElastiCache Redis Cache"
  from_port   = local.elasticache_redis_cache_port
  to_port     = local.elasticache_redis_cache_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.elasticache_redis_cache_allowed_ingress_cidr_blocks, var.elasticache_redis_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

### Redis Persistent
resource "aws_security_group" "gitlab_elasticache_redis_persistent" {
  count = min(var.elasticache_redis_persistent_node_count, 1)

  name_prefix = "${var.prefix}-elasticache-redis-persistent-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-elasticache-redis-persistent"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_elasticache_redis_persistent" {
  count = min(var.elasticache_redis_persistent_node_count, 1)

  security_group_id = aws_security_group.gitlab_elasticache_redis_persistent[0].id

  type        = "ingress"
  description = "Enable internal access to ElastiCache Redis Persistent"
  from_port   = local.elasticache_redis_persistent_port
  to_port     = local.elasticache_redis_persistent_port
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.elasticache_redis_persistent_allowed_ingress_cidr_blocks, var.elasticache_redis_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

## AWS OpenSearch
resource "aws_security_group" "gitlab_opensearch" {
  count = min(var.opensearch_node_count, 1)

  name_prefix = "${var.prefix}-opensearch-"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Name = "${var.prefix}-opensearch"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "gitlab_opensearch" {
  count = min(var.opensearch_node_count, 1)

  security_group_id = aws_security_group.gitlab_opensearch[0].id

  type        = "ingress"
  description = "Enable internal HTTPS access for OpenSearch"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = coalescelist(var.opensearch_allowed_ingress_cidr_blocks, [data.aws_vpc.selected.cidr_block])
}

# Ensure correct order for OpenSearch security group switch
# To be removed in 3.x
moved {
  from = aws_security_group.gitlab_opensearch_security_group
  to   = aws_security_group.gitlab_opensearch
}
