resource "google_compute_firewall" "gitlab_http_https" {
  count = min(var.haproxy_external_node_count + var.monitor_node_count, 1)
  name = "${var.prefix}-gitlab-rails-firewall-rule-http-https"
  network = "default"

  description = "Allow external load balancer access"

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
  count = min(var.haproxy_external_node_count, 1)
  name    = "${var.prefix}-gitlab-rails-firewall-rule-ssh"
  network = "default"

  description = "Allow access to GitLab SSH via external load balancer"

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
  count = min(var.haproxy_external_node_count + var.haproxy_internal_node_count, 1)
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
  count = min(var.monitor_node_count, 1)
  name    = "${var.prefix}-monitor-firewall-rule"
  network = "default"

  description = "Allow Prometheus and InfluxDB exporter access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["9122", "9090", "5601"]
  }

  target_tags   = ["${var.prefix}-monitor"]
}
