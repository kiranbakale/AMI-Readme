variable "pgbouncer_count" {
  description = "Number of pgbouncer nodes to create"
  default = 1
}

resource "google_compute_address" "pgbouncer_ip" {
  count = var.pgbouncer_count
  name = "${var.prefix}-pgbouncer-ip-${count.index + 1}"
}

resource "google_compute_instance" "pgbouncer" {
  count = var.pgbouncer_count
  name = "${var.prefix}-pgbouncer-${count.index + 1}"
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
    gitlab_node_type = "pgbouncer"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.pgbouncer_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "pgbouncer-machine-names" {
  value = google_compute_instance.pgbouncer[*].name
}

output "pgbouncer-internal-addresses" {
  value = google_compute_instance.pgbouncer[*].network_interface[0].network_ip
}

output "pgbouncer-addresses" {
  value = google_compute_instance.pgbouncer[*].network_interface[0].access_config[0].nat_ip
}

