# https://binx.io/blog/2018/11/19/how-to-configure-global-load-balancing-with-google-cloud-platform/
/*
resource "google_compute_global_address" "gitlab" {
  name = "${var.prefix}-gitlab-rails-global-address"
}

resource "google_compute_global_forwarding_rule" "gitlab" {
  name       = "${var.prefix}-gitlab-rails-rule-80"
  ip_address = google_compute_global_address.gitlab.address
  port_range = "80"
  target     = google_compute_target_http_proxy.gitlab.self_link
}

resource "google_compute_target_http_proxy" "gitlab" {
  name    = "${var.prefix}-gitlab-rails-target-http-proxy"
  url_map = google_compute_url_map.gitlab.self_link
}

resource "google_compute_url_map" "gitlab" {
  name        = "${var.prefix}-gitlab-rails-url-map"
  default_service = google_compute_backend_service.gitlab.self_link
}

resource "google_compute_backend_service" "gitlab" {
  name        = "${var.prefix}-gitlab-rails-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 120

  backend {
    group = google_compute_instance_group.gitlab_rails.self_link
  }

  session_affinity = "GENERATED_COOKIE"

  health_checks = [google_compute_health_check.gitlab.self_link]
}

resource "google_compute_health_check" "gitlab" {
  name = "${var.prefix}-gitlab-rails-health-check"

  timeout_sec        = 60
  check_interval_sec = 60

  http_health_check {
    port = 80
    request_path = "/-/health"
  }
}

output "gitlab-rails-load-balancer-ip" {
  value = google_compute_global_address.gitlab.address
}
*/