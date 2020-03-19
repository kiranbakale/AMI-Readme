module "redis" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis"
  node_count = 3

  machine_type = "n1-standard-8"
  machine_image = "${var.machine_image}"
  label_secondaries = true
}

output "redis" {
  value = module.redis
}

module "redis_sentinel" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis-sentinel"
  node_count = 3

  machine_type = "g1-small"
  machine_image = "${var.machine_image}"
  label_secondaries = true
}

output "redis_sentinel" {
  value = module.redis_sentinel
}
