module "gitlab_rails" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitlab-rails"
  node_count = 20

  machine_type = "custom-16-16384"
  ssh_public_key = var.ssh_public_key
  # global_ip = google_compute_global_address.gitlab.address

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