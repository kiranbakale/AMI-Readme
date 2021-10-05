module "redis" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis"
  node_count = var.redis_node_count

  machine_type  = var.redis_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.redis_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_disk_type, var.default_disk_type)
  disks         = var.redis_disks

  vpc               = local.vpc_name
  subnet            = local.subnet_name
  setup_external_ip = var.setup_external_ips

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis" {
  value = module.redis
}

# Redis Separated

module "redis_cache" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis-cache"
  node_count = var.redis_cache_node_count

  machine_type  = var.redis_cache_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_cache_disk_type, var.default_disk_type)
  disks         = var.redis_cache_disks

  vpc               = local.vpc_name
  subnet            = local.subnet_name
  setup_external_ip = var.setup_external_ips

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_persistent" {
  source = "../gitlab_gcp_instance"

  prefix     = var.prefix
  node_type  = "redis-persistent"
  node_count = var.redis_persistent_node_count

  machine_type  = var.redis_persistent_machine_type
  machine_image = var.machine_image
  disk_size     = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_persistent_disk_type, var.default_disk_type)
  disks         = var.redis_persistent_disks

  vpc               = local.vpc_name
  subnet            = local.subnet_name
  setup_external_ip = var.setup_external_ips

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_persistent" {
  value = module.redis_persistent
}
