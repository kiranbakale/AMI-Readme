module "jaeger" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "jaeger"
  node_count = 0

  machine_type = "n1-standard-2"
  machine_image = "${var.machine_image}"

  tags = ["${var.prefix}-jaeger"]
}

resource "google_compute_firewall" "jaeger" {
  name    = "${var.prefix}-jaeger-firewall-rule"
  network = "default"

  description = "Allow Jaeger access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["16686"]
  }

  target_tags   = ["${var.prefix}-jaeger"]
}

output "jaeger" {
  value = module.jaeger
}
