resource "google_compute_firewall" "gitlab_http_https" {
  ## firewall rules enabling the load balancer health checks
  name    = "${var.prefix}-gitlab-rails-firewall-rule-http-https"
  network = "default"

  description = "Allow Google health checks and network load balancers access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  # source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["${var.prefix}-web"]
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
