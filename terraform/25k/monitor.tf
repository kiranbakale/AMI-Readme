module "monitor" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "monitor"
  node_count = 1

  ssh_public_key = var.ssh_public_key
  global_ip = google_compute_global_address.gitlab.address
  tags = ["${var.prefix}-web", "${var.prefix}-monitor"]
}

output "monitor" {
  value = module.monitor
}