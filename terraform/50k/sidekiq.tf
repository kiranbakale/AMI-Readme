module "sidekiq" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "sidekiq"
  node_count = 8

  machine_type = "n1-standard-4"
  ssh_public_key = var.ssh_public_key
  global_ip = google_compute_global_address.gitlab.address
}