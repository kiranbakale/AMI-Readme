variable "sidekiq_count" {
  description = "Number of sidekiq nodes to create"
  default = 4
}

resource "google_compute_address" "sidekiq_ip" {
  count = var.sidekiq_count
  name = "${var.prefix}-sidekiq-ip-${count.index + 1}"
}

resource "google_compute_instance" "sidekiq" {
  count = var.sidekiq_count
  name = "${var.prefix}-sidekiq-${count.index + 1}"
  machine_type = "n1-standard-4"

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
      size = "100"
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  labels = {
    gitlab_node_type = "sidekiq"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.sidekiq_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "sidekiq-machine-names" {
  value = google_compute_instance.sidekiq[*].name
}

output "sidekiq-internal-addresses" {
  value = google_compute_instance.sidekiq[*].network_interface[0].network_ip
}

output "sidekiq-addresses" {
  value = google_compute_instance.sidekiq[*].network_interface[0].access_config[0].nat_ip
}

