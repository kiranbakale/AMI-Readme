variable "redis_count" {
  description = "Number of redis nodes to create"
  default = 2
}

resource "google_compute_address" "redis_ip" {
  count = var.redis_count
  name = "${var.prefix}-redis-ip-${count.index + 1}"
}

resource "google_compute_instance" "redis" {
  count = var.redis_count
  name = "${var.prefix}-redis-${count.index + 1}"
  machine_type = "n1-standard-2"

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
    gitlab_node_type = count.index == 0 ? "redis_primary" : "redis_secondary"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.redis_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "redis-machine-names" {
  value = google_compute_instance.redis[*].name
}

output "redis-internal-addresses" {
  value = google_compute_instance.redis[*].network_interface[0].network_ip
}

output "redis-addresses" {
  value = google_compute_instance.redis[*].network_interface[0].access_config[0].nat_ip
}

