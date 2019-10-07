module "redis-cache" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis-cache"
  node_count = 3

  machine_type = "n1-highcpu-4"
  label_secondaries = true
}

output "redis-cache" {
  value = module.redis-cache
}

module "redis-persistent" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis-persistent"
  node_count = 3

  machine_type = "n1-highcpu-4"
  label_secondaries = true
}

output "redis-persistent" {
  value = module.redis-persistent
}