#module "gce-lb-fr" {
#  source       = "GoogleCloudPlatform/lb/google"
#  region       = "${var.region}"
#  name         = "${var.prefix}-lb"
#  service_port = "80"
#  target_tags  = ["${var.prefix}-web"]
#}

#output "load-balancer-ip" {
#  value = "${module.gce-lb-fr.external_ip}"
#}

# https://binx.io/blog/2018/11/19/how-to-configure-global-load-balancing-with-google-cloud-platform/

resource "google_compute_global_address" "gitlab_rails" {
  name = "${var.prefix}-gitlab-rails-global-address"
}

resource "google_compute_global_forwarding_rule" "gitlab_rails" {
  name       = "${var.prefix}-gitlab-rails-rule-80"
  ip_address = google_compute_global_address.gitlab_rails.address
  port_range = "80"
  target     = google_compute_target_http_proxy.gitlab_rails.self_link
}

resource "google_compute_target_http_proxy" "gitlab_rails" {
  name    = "${var.prefix}-gitlab-rails-target-http-proxy"
  url_map = google_compute_url_map.gitlab_rails.self_link
}

resource "google_compute_url_map" "gitlab_rails" {
  name        = "${var.prefix}-gitlab-rails-url-map"
  default_service = google_compute_backend_service.gitlab_rails.self_link
}

resource "google_compute_backend_service" "gitlab_rails" {
  name        = "${var.prefix}-gitlab-rails-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.gitlab_rails.self_link
  }

  health_checks = [google_compute_health_check.gitlab_rails.self_link]
}

resource "google_compute_health_check" "gitlab_rails" {
  name = "${var.prefix}-gitlab-rails-health-check"

  timeout_sec        = 10
  check_interval_sec = 10

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_firewall" "gitlab_rails" {
  ## firewall rules enabling the load balancer health checks
  name    = "${var.prefix}-gitlab-rails-firewall-rule"
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

output "gitlab-rails-load-balancer-ip" {
  value = google_compute_global_address.gitlab_rails.address
}