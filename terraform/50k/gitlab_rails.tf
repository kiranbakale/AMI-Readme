module "gitlab_rails" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitlab-rails"
  node_count = 12

  machine_type = "n1-highcpu-32"
  machine_image = "${var.machine_image}"
  label_secondaries = true

  tags = ["${var.prefix}-web"]
}

resource "google_compute_instance_group" "gitlab_rails" {
  name = "${var.prefix}-gitlab-rails-group"

  instances = module.gitlab_rails.self_links

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
