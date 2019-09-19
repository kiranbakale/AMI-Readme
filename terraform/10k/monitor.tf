variable "monitor_count" {
  description = "Number of monitor nodes to create"
  default = 3
}

resource "google_compute_address" "monitor_ip" {
  count = var.monitor_count
  name = "${var.prefix}-monitor-ip-${count.index + 1}"
}

resource "google_compute_instance" "monitor" {
  count = var.monitor_count
  name = "${var.prefix}-monitor-${count.index + 1}"
  machine_type = "n1-standard-2"
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
    gitlab_node_type = "monitor"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.monitor_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "monitor-machine-names" {
  value = google_compute_instance.monitor[*].name
}

output "monitor-internal-addresses" {
  value = google_compute_instance.monitor[*].network_interface[0].network_ip
}

output "monitor-addresses" {
  value = google_compute_instance.monitor[*].network_interface[0].access_config[0].nat_ip
}

