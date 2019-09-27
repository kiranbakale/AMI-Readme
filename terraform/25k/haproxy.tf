module "haproxy" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "haproxy"
  node_count = 1

  machine_type = "n1-highcpu-4"
  # ssh_public_key = var.ssh_public_key
  tags = ["${var.prefix}-web", "${var.prefix}-haproxy"]
}

resource "google_compute_firewall" "haproxy" {
  ## firewall rules enabling the load balancer health checks
  name    = "${var.prefix}-haproxy-firewall-rule"
  network = "default"

  description = "Allow HAProxy Stats access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1936"]
  }

  target_tags   = ["${var.prefix}-haproxy"]
}

output "haproxy" {
  value = module.haproxy
}
