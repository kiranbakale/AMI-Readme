variable "gitaly_count" {
  description = "Number of gitaly nodes to create"
  default = 1
}

resource "google_compute_address" "gitaly_ip" {
  count = var.gitaly_count
  name = "${var.prefix}-gitaly-ip-${count.index + 1}"
}

resource "google_compute_instance" "gitaly" {
  count = var.gitaly_count
  name = "${var.prefix}-gitaly-${count.index + 1}"
  machine_type = "n1-standard-16"

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
    gitlab_node_type = "gitaly"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.gitaly_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "gitaly-machine-names" {
  value = google_compute_instance.gitaly[*].name
}

output "gitaly-internal-addresses" {
  value = google_compute_instance.gitaly[*].network_interface[0].network_ip
}

output "gitaly-addresses" {
  value = google_compute_instance.gitaly[*].network_interface[0].access_config[0].nat_ip
}

