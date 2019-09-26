module "redis" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "redis"
  node_count = 2

  ssh_public_key = var.ssh_public_key
  # global_ip = google_compute_global_address.gitlab.address
}

output "redis" {
  value = module.redis
}
