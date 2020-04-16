resource "google_compute_firewall" "gitlab_http_https" {
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

  target_tags   = ["${var.prefix}-web"]
}

resource "google_compute_firewall" "monitor" {
  name    = "${var.prefix}-monitor-firewall-rule"
  network = "default"

  description = "Allow Prometheus and InfluxDB access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8086", "9090"]
  }

  target_tags   = ["${var.prefix}-monitor"]
}
