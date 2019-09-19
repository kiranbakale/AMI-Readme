variable "gitlab_rails_count" {
  description = "Number of database nodes to create"
  default = 5
}

resource "google_compute_address" "gitlab_rails_ip" {
  count = var.gitlab_rails_count
  name = "${var.prefix}-gitlab-rails-ip-${count.index + 1}"
}

resource "google_compute_instance" "gitlab_rails" {
  count = var.gitlab_rails_count
  name = "${var.prefix}-gitlab-rails-${count.index + 1}"
  machine_type = "n1-standard-16"
  tags = ["${var.prefix}-web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
      size = "100"
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
    global_ip = google_compute_global_address.gitlab_rails.address
  }

  labels = {
    gitlab_node_type = count.index == 0 ? "gitlab_rails_primary" : "gitlab_rails_secondary"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.gitlab_rails_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

resource "google_compute_instance_group" "gitlab_rails" {
  name = "${var.prefix}-gitlab-rails-group"

  instances = google_compute_instance.gitlab_rails[*].self_link

  named_port {
    name = "http"
    port = "80"
  }
}

output "gitlab-rails-machine-names" {
  value = google_compute_instance.gitlab_rails[*].name
}

output "gitlab-rails-internal-addresses" {
  value = google_compute_instance.gitlab_rails[*].network_interface[0].network_ip
}

output "gitlab-rails-addresses" {
  value = google_compute_instance.gitlab_rails[*].network_interface[0].access_config[0].nat_ip
}

