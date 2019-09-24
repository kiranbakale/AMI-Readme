module "gitaly" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitaly"

  machine_type = "n1-standard-32"
  ssh_public_key = var.ssh_public_key
  global_ip = google_compute_global_address.gitlab.address
}

output "gitaly" {
  value = module.gitaly
}