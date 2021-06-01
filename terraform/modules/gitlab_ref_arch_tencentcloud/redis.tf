module "redis" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "redis"
  node_count = var.redis_node_count

  instance_type = var.redis_instance_type
  disk_size     = coalesce(var.redis_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis" {
  value = module.redis
}

# Redis Separate Cache

module "redis_cache" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "redis-cache"
  node_count = var.redis_cache_node_count

  instance_type = var.redis_cache_instance_type
  disk_size     = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_cache_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_sentinel_cache" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "redis-sentinel-cache"
  node_count = var.redis_sentinel_cache_node_count

  instance_type = var.redis_sentinel_cache_instance_type
  disk_size     = coalesce(var.redis_sentinel_cache_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_sentinel_cache_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_sentinel_cache" {
  value = module.redis_sentinel_cache
}

module "redis_persistent" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "redis-persistent"
  node_count = var.redis_persistent_node_count

  instance_type = var.redis_persistent_instance_type
  disk_size     = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_persistent_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_persistent" {
  value = module.redis_persistent
}

module "redis_sentinel_persistent" {
  source = "../gitlab_tencentcloud_instance"

  prefix     = var.prefix
  node_type  = "redis-sentinel-persistent"
  node_count = var.redis_sentinel_persistent_node_count

  instance_type = var.redis_sentinel_persistent_instance_type
  disk_size     = coalesce(var.redis_sentinel_persistent_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_sentinel_persistent_disk_type, var.default_disk_type)

  security_group_ids = [tencentcloud_security_group.gitlab_external_ssh.id]
  vpc_id             = tencentcloud_vpc.vpc.id
  subnet_id          = tencentcloud_subnet.default.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_sentinel_persistent" {
  value = module.redis_sentinel_persistent
}
