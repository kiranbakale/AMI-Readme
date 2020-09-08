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

resource "google_compute_firewall" "gitlab_ssh" {
  name    = "${var.prefix}-gitlab-rails-firewall-rule-ssh"
  network = "default"

  description = "Allow access to GitLab SSH"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["2222"]
  }

  target_tags   = ["${var.prefix}-ssh"]
}

resource "google_compute_firewall" "haproxy_stats" {
  ## firewall rules enabling the load balancer health checks
  name    = "${var.prefix}-haproxy-stats-firewall-rule"
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

resource "google_compute_firewall" "monitor" {
  name    = "${var.prefix}-monitor-firewall-rule"
  network = "default"

 description = "Allow Prometheus and InfluxDB access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["8086", "9090", "5601"]
  }

  target_tags   = ["${var.prefix}-monitor"]
}
