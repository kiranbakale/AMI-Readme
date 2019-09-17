resource "google_compute_address" "vm_static_ip" {
  name = "${var.prefix}-static-ip"
}

resource "google_compute_instance" "vm_instance" {
  name         = "${var.prefix}-terraform-instance"
  machine_type = "n2-standard-4"
  tags = ["${var.prefix}-web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  metadata = {
    ssh-keys = var.ssh_public_key
  }

  labels = {
    gitlab_node_type = "postgres_primary"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}

resource "google_compute_firewall" "default" {
 name    = "${var.prefix}-firewall"
 network = "default"

 allow {
   protocol = "icmp"
 }

 allow {
   protocol = "tcp"
   ports    = ["80"]
 }

 source_ranges = ["0.0.0.0/0"]
 target_tags = ["${var.prefix}-web"]
}