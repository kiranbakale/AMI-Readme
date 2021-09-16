resource "google_compute_router" "router" {
  count   = (var.use_existing_nat || var.setup_external_ips) ? 0 : 1
  name    = "${var.prefix}-router"
  network = "default"
}

resource "google_compute_router_nat" "nat" {
  count  = (var.use_existing_nat || var.setup_external_ips) ? 0 : 1
  name   = "${var.prefix}-nat"
  router = google_compute_router.router[0].name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
