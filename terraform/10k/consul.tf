variable "consul_count" {
  description = "Number of consul nodes to create"
  default = 3
}

resource "google_compute_address" "consul_ip" {
  count = var.consul_count
  name = "${var.prefix}-consul-ip-${count.index + 1}"
}

resource "google_compute_instance" "consul" {
  count = var.consul_count
  name = "${var.prefix}-consul-${count.index + 1}"
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
    gitlab_node_type = "consul"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.consul_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "consul-machine-names" {
  value = google_compute_instance.consul[*].name
}

output "consul-internal-addresses" {
  value = google_compute_instance.consul[*].network_interface[0].network_ip
}

output "consul-addresses" {
  value = google_compute_instance.consul[*].network_interface[0].access_config[0].nat_ip
}

