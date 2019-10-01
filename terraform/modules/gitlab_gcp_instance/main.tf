resource "google_compute_address" "gitlab" {
  count = var.node_count
  name = "${var.prefix}-${var.node_type}-ip-${count.index + 1}"
}

resource "google_compute_instance" "gitlab" {
  count = var.node_count
  name = "${var.prefix}-${var.node_type}-${count.index + 1}"
  machine_type = var.machine_type
  tags = var.tags
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.machine_image
      size = var.disk_size
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = {
    gitlab_node_type = var.node_type
    gitlab_node_level = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.gitlab[count.index].address
    }
  }

  service_account {
    scopes = ["storage-rw"]
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }
}
