variable "haproxy_count" {
  description = "Number of haproxy nodes to create"
  default = 1
}

resource "google_compute_address" "haproxy_ip" {
  count = var.haproxy_count
  name = "${var.prefix}-haproxy-ip-${count.index + 1}"
}

resource "google_compute_instance" "haproxy" {
  count = var.haproxy_count
  name = "${var.prefix}-haproxy-${count.index + 1}"
  machine_type = "n1-highcpu-4"
  tags = ["${var.prefix}-web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
      size = "20"
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  labels = {
    gitlab_node_type = "haproxy"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.haproxy_ip[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}

output "haproxy-machine-names" {
  value = google_compute_instance.haproxy[*].name
}

output "haproxy-internal-addresses" {
  value = google_compute_instance.haproxy[*].network_interface[0].network_ip
}

output "haproxy-addresses" {
  value = google_compute_instance.haproxy[*].network_interface[0].access_config[0].nat_ip
}