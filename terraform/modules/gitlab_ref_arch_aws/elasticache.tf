resource "aws_elasticache_subnet_group" "gitlab" {
  count = sum([var.elasticache_redis_node_count, var.elasticache_redis_cache_node_count, var.elasticache_redis_persistent_node_count]) > 0 ? 1 : 0

  name = "${var.prefix}-redis-subnet-group"
  subnet_ids = coalesce(local.subnet_ids, local.default_subnet_ids)

  tags = {
    Name = "${var.prefix}-redis-subnet-group"
  }
}

# Redis Combined
resource "aws_elasticache_replication_group" "gitlab_redis" {
  count = var.elasticache_redis_node_count > 0 ? 1 : 0

  replication_group_id = "${format("%.34s", var.prefix)}-redis" # Must be 40 characters or lower
  replication_group_description = "${var.prefix}-redis"
  node_type = "cache.${var.elasticache_redis_instance_type}"
  number_cache_clusters = var.elasticache_redis_node_count
  
  engine_version = var.elasticache_redis_engine_version
  port = var.elasticache_redis_port
  multi_az_enabled = var.elasticache_redis_multi_az
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = true

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output elasticache_redis_connection {
  value = {
    "elasticache_redis_address" = try(aws_elasticache_replication_group.gitlab_redis[0].primary_endpoint_address, "")
    "elasticache_redis_port" = try(aws_elasticache_replication_group.gitlab_redis[0].port, "")
  }
}

# Redis Separate Cache

## Use default values if specifics aren't specfied
locals {
  cache_engine_version = coalesce(var.elasticache_redis_cache_engine_version, var.elasticache_redis_engine_version)
  cache_port = coalesce(var.elasticache_redis_cache_port, var.elasticache_redis_port)
  cache_multi_az = coalesce(var.elasticache_redis_cache_multi_az, var.elasticache_redis_multi_az)
}

resource "aws_elasticache_parameter_group" "gitlab_redis_cache" {
  count = var.elasticache_redis_cache_node_count > 0 ? 1 : 0

  name   = "${var.prefix}-redis-cache-parameter-group"
  family = "redis${local.cache_engine_version}"

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

  replication_group_id = "${format("%.28s", var.prefix)}-redis-cache" # Must be 40 characters or lower
  replication_group_description = "${var.prefix}-redis-cache"
  node_type = "cache.${var.elasticache_redis_cache_instance_type}"
  number_cache_clusters = var.elasticache_redis_cache_node_count
  parameter_group_name = aws_elasticache_parameter_group.gitlab_redis_cache[0].name

  engine_version = local.cache_engine_version
  port = local.cache_port
  multi_az_enabled = local.cache_multi_az
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = true

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output elasticache_redis_cache_connection {
  value = {
    "elasticache_redis_cache_address" = try(aws_elasticache_replication_group.gitlab_redis_cache[0].primary_endpoint_address, "")
    "elasticache_redis_port" = try(aws_elasticache_replication_group.gitlab_redis_cache[0].port, "")
  }
}

# Redis Separate Persistent

## Use default values if specifics aren't specfied
locals {
  persistent_engine_version = coalesce(var.elasticache_redis_persistent_engine_version, var.elasticache_redis_engine_version)
  persistent_port = coalesce(var.elasticache_redis_persistent_port, var.elasticache_redis_port)
  persistent_multi_az = coalesce(var.elasticache_redis_persistent_multi_az, var.elasticache_redis_multi_az)
}

resource "aws_elasticache_replication_group" "gitlab_redis_persistent" {
  count = var.elasticache_redis_persistent_node_count > 0 ? 1 : 0

  replication_group_id = "${format("%.23s", var.prefix)}-redis-persistent" # Must be 40 characteers or lower
  replication_group_description = "${var.prefix}-redis-persistent"
  node_type = "cache.${var.elasticache_redis_persistent_instance_type}"
  number_cache_clusters = var.elasticache_redis_persistent_node_count

  engine_version = local.persistent_engine_version
  port = local.persistent_port
  multi_az_enabled = local.persistent_multi_az
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = true

  subnet_group_name = aws_elasticache_subnet_group.gitlab[0].name
  security_group_ids = [
    aws_security_group.gitlab_internal_networking.id
  ]
}

output elasticache_redis_persistent_connection {
  value = {
    "elasticache_redis_persistent_address" = try(aws_elasticache_replication_group.gitlab_redis_persistent[0].primary_endpoint_address, "")
    "elasticache_redis_port" = try(aws_elasticache_replication_group.gitlab_redis_persistent[0].port, "")
  }
}
