locals {
  elasticache_redis_subnet_ids = local.subnet_ids != null ? local.subnet_ids : slice(tolist(local.default_subnet_ids), 0, var.elasticache_redis_default_subnet_count)
}

resource "aws_elasticache_subnet_group" "gitlab" {
  count = sum([var.elasticache_redis_node_count, var.elasticache_redis_cache_node_count, var.elasticache_redis_persistent_node_count]) > 0 ? 1 : 0

  name       = "${var.prefix}-redis-subnet-group"
  subnet_ids = local.elasticache_redis_subnet_ids

  tags = {
    Name = "${var.prefix}-redis-subnet-group"
  }
}

# Redis Combined

locals {
  elasticache_redis_kms_key_create = var.elasticache_redis_node_count > 0 && var.elasticache_redis_kms_key_arn == null
}

resource "aws_kms_key" "gitlab_elasticache_redis_kms_key" {
  count = local.elasticache_redis_kms_key_create ? 1 : 0

  description = "${var.prefix} Elasticache Redis KMS Key"

  tags = {
    Name = "${var.prefix}-rds-elasticache-redis-key"
  }
}

resource "aws_elasticache_replication_group" "gitlab_redis" {
  count = var.elasticache_redis_node_count > 0 ? 1 : 0

  replication_group_id          = "${format("%.34s", var.prefix)}-redis" # Must be 40 characters or lower
  replication_group_description = "${var.prefix}-redis"
  node_type                     = "cache.${var.elasticache_redis_instance_type}"
  number_cache_clusters         = var.elasticache_redis_node_count

  engine_version             = var.elasticache_redis_engine_version
  port                       = var.elasticache_redis_port
  multi_az_enabled           = var.elasticache_redis_multi_az
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = local.elasticache_redis_kms_key_create ? aws_kms_key.gitlab_elasticache_redis_kms_key[0].arn : var.elasticache_redis_kms_key_arn
  auth_token                 = var.elasticache_redis_password

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output "elasticache_redis_connection" {
  value = {
    "elasticache_redis_host"        = try(aws_elasticache_replication_group.gitlab_redis[0].primary_endpoint_address, "")
    "elasticache_redis_port"        = try(aws_elasticache_replication_group.gitlab_redis[0].port, "")
    "elasticache_redis_kms_key_arn" = try(aws_elasticache_replication_group.gitlab_redis[0].kms_key_id, "")
  }
}

# Redis Separate Cache

locals {
  elasticache_redis_cache_kms_key_create = var.elasticache_redis_cache_node_count > 0 && var.elasticache_redis_cache_kms_key_arn == null

  ## Use default values if specifics aren't specfied
  elasticache_redis_cache_engine_version = coalesce(var.elasticache_redis_cache_engine_version, var.elasticache_redis_engine_version)
  elasticache_redis_cache_password       = var.elasticache_redis_cache_password != "" ? var.elasticache_redis_cache_password : var.elasticache_redis_password
  elasticache_redis_cache_port           = coalesce(var.elasticache_redis_cache_port, var.elasticache_redis_port)
  elasticache_redis_cache_multi_az       = coalesce(var.elasticache_redis_cache_multi_az, var.elasticache_redis_multi_az)
}

resource "aws_kms_key" "gitlab_elasticache_redis_cache_kms_key" {
  count = local.elasticache_redis_cache_kms_key_create ? 1 : 0

  description = "${var.prefix} Elasticache Redis Cache KMS Key"

  tags = {
    Name = "${var.prefix}-rds-elasticache-redis-cache-key"
  }
}

resource "aws_elasticache_parameter_group" "gitlab_redis_cache" {
  count = var.elasticache_redis_cache_node_count > 0 ? 1 : 0

  name   = "${var.prefix}-redis-cache-parameter-group"
  family = "redis${local.elasticache_redis_cache_engine_version}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "maxmemory-samples"
    value = "5"
  }
}

resource "aws_elasticache_replication_group" "gitlab_redis_cache" {
  count = var.elasticache_redis_cache_node_count > 0 ? 1 : 0

  replication_group_id          = "${format("%.28s", var.prefix)}-redis-cache" # Must be 40 characters or lower
  replication_group_description = "${var.prefix}-redis-cache"
  node_type                     = "cache.${var.elasticache_redis_cache_instance_type}"
  number_cache_clusters         = var.elasticache_redis_cache_node_count
  parameter_group_name          = aws_elasticache_parameter_group.gitlab_redis_cache[0].name

  engine_version             = local.elasticache_redis_cache_engine_version
  port                       = local.elasticache_redis_cache_port
  multi_az_enabled           = local.elasticache_redis_cache_multi_az
  automatic_failover_enabled = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = local.elasticache_redis_cache_kms_key_create ? aws_kms_key.gitlab_elasticache_redis_cache_kms_key[0].arn : var.elasticache_redis_cache_kms_key_arn
  auth_token                 = local.elasticache_redis_cache_password

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output "elasticache_redis_cache_connection" {
  value = {
    "elasticache_redis_cache_host"        = try(aws_elasticache_replication_group.gitlab_redis_cache[0].primary_endpoint_address, "")
    "elasticache_redis_cache_port"        = try(aws_elasticache_replication_group.gitlab_redis_cache[0].port, "")
    "elasticache_redis_cache_kms_key_arn" = try(aws_elasticache_replication_group.gitlab_redis_cache[0].kms_key_id, "")
  }
}

# Redis Separate Persistent

locals {
  elasticache_redis_persistent_kms_key_create = var.elasticache_redis_persistent_node_count > 0 && var.elasticache_redis_persistent_kms_key_arn == null

  ## Use default values if specifics aren't specfied
  elasticache_redis_persistent_password       = var.elasticache_redis_persistent_password != "" ? var.elasticache_redis_persistent_password : var.elasticache_redis_password
  elasticache_redis_persistent_engine_version = coalesce(var.elasticache_redis_persistent_engine_version, var.elasticache_redis_engine_version)
  elasticache_redis_persistent_port           = coalesce(var.elasticache_redis_persistent_port, var.elasticache_redis_port)
  elasticache_redis_persistent_multi_az       = coalesce(var.elasticache_redis_persistent_multi_az, var.elasticache_redis_multi_az)
}

resource "aws_kms_key" "gitlab_elasticache_redis_persistent_kms_key" {
  count = local.elasticache_redis_persistent_kms_key_create ? 1 : 0

  description = "${var.prefix} Elasticache Redis Persistent KMS Key"

  tags = {
    Name = "${var.prefix}-rds-elasticache-redis-persistent-key"
  }
}

resource "aws_elasticache_replication_group" "gitlab_redis_persistent" {
  count = var.elasticache_redis_persistent_node_count > 0 ? 1 : 0

  replication_group_id          = "${format("%.23s", var.prefix)}-redis-persistent" # Must be 40 characteers or lower
  replication_group_description = "${var.prefix}-redis-persistent"
  node_type                     = "cache.${var.elasticache_redis_persistent_instance_type}"
  number_cache_clusters         = var.elasticache_redis_persistent_node_count

  engine_version             = local.elasticache_redis_persistent_engine_version
  port                       = local.elasticache_redis_persistent_port
  multi_az_enabled           = local.elasticache_redis_persistent_multi_az
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = local.elasticache_redis_persistent_kms_key_create ? aws_kms_key.gitlab_elasticache_redis_persistent_kms_key[0].arn : var.elasticache_redis_persistent_kms_key_arn
  auth_token                 = local.elasticache_redis_persistent_password

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output "elasticache_redis_persistent_connection" {
  value = {
    "elasticache_redis_persistent_host"        = try(aws_elasticache_replication_group.gitlab_redis_persistent[0].primary_endpoint_address, "")
    "elasticache_redis_persistent_port"        = try(aws_elasticache_replication_group.gitlab_redis_persistent[0].port, "")
    "elasticache_redis_persistent_kms_key_arn" = try(aws_elasticache_replication_group.gitlab_redis_persistent[0].kms_key_id, "")
  }
}
