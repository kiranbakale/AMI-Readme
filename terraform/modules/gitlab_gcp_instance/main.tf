locals {
  node_disks = flatten([
    for i in range(var.node_count) :
    [
      for disk in var.disks : {
        size    = disk.size
        type    = disk.type
        device_name = disk.device_name
        item    = i
      }
    ]
  ])
}

resource "google_compute_disk" "gitlab" {
  for_each = { for d in local.node_disks : format("%s-%d", d.device_name, d.item) => d }
  name     = format("%s-%s-%s-%d", var.prefix, var.node_type, each.value.device_name, each.value.item)
  type     = each.value.type
  size     = each.value.size
}

resource "google_compute_address" "gitlab" {
  count = length(var.external_ips) == 0 ? var.node_count : 0
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
      type = var.disk_type
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  labels = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type = var.node_type
    gitlab_node_level = var.label_secondaries == true ? (count.index == 0 ? "${var.node_type}-primary" : "${var.node_type}-secondary") : ""
    gitlab_geo_site = var.geo_site
    gitlab_geo_deployment = var.geo_deployment
    gitlab_geo_full_role = var.geo_site == null ? null : (count.index == 0 ? "${var.geo_site}-${var.node_type}-primary" : "${var.geo_site}-${var.node_type}-secondary")
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = length(var.external_ips) == 0 ? google_compute_address.gitlab[count.index].address : var.external_ips[count.index]
    }
  }

  service_account {
    scopes = concat(["storage-rw"], var.scopes)
  }

  lifecycle {
    ignore_changes = [
      min_cpu_platform
    ]
  }

  dynamic "attached_disk" {
    for_each = var.disks
    content {
      source = google_compute_disk.gitlab[format("%s-%d", attached_disk.value["device_name"], count.index)].self_link
      device_name = attached_disk.value["device_name"]
    }
  }
}
