variable "postgres_count" {
  description = "Number of database nodes to create"
  default = 3
}

resource "google_compute_address" "postgres_ip" {
  count = var.postgres_count
  name = "${var.prefix}-postgres-ip-${count.index + 1}"
}

resource "google_compute_instance" "postgres" {
  count = var.postgres_count
  name = "${var.prefix}-postgres-${count.index + 1}"
  machine_type = "n2-standard-4"

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
    gitlab_node_type = count.index == 0 ? "postgres_primary" : "postgres_secondary"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.postgres_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "postgres-machine-names" {
  value = google_compute_instance.postgres[*].name
}

output "postgres-internal-addresses" {
  value = google_compute_instance.postgres[*].network_interface[0].network_ip
}

output "postgres-addresses" {
  value = google_compute_instance.postgres[*].network_interface[0].access_config[0].nat_ip
}

