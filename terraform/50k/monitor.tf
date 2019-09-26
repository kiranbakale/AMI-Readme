module "monitor" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "monitor"
  node_count = 1

  machine_type = "n1-highcpu-4"
  ssh_public_key = var.ssh_public_key
  # global_ip = google_compute_global_address.gitlab.address
  tags = ["${var.prefix}-web", "${var.prefix}-monitor"]
}

resource "google_compute_firewall" "monitor" {
  ## firewall rules enabling the load balancer health checks
  name    = "${var.prefix}-monitor-firewall-rule"
  network = "default"

  description = "Allow Prometheus access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  target_tags   = ["${var.prefix}-monitor"]
}
