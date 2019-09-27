module "postgres" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "postgres"
  node_count = 3

  machine_type = "n1-standard-8"
  # ssh_public_key = var.ssh_public_key
  # global_ip = google_compute_global_address.gitlab.address
}

output "postgres" {
  value = module.postgres
}
