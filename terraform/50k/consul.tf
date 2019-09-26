module "consul" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "consul"
  node_count = 3

  machine_type = "n1-highcpu-2"
  ssh_public_key = var.ssh_public_key
  # global_ip = google_compute_global_address.gitlab.address
}

output "consul" {
  value = module.consul
}