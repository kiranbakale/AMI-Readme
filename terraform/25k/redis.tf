module "redis" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis"
  node_count = 2

  machine_type = "n1-standard-4"
  label_secondaries = true
}

output "redis" {
  value = module.redis
}
