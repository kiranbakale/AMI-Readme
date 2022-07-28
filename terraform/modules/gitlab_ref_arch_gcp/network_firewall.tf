resource "google_compute_firewall" "gitlab_http_https" {
  count   = min(var.haproxy_external_node_count + var.monitor_node_count, 1)
  name    = "${var.prefix}-gitlab-rails-http-https"
  network = local.vpc_name

  description = "Allow external load balancer access for GitLab environment '${var.prefix}' on the ${local.vpc_name} network"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = coalescelist(var.http_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  target_tags   = ["${var.prefix}-web"]
}

resource "google_compute_firewall" "gitlab_ssh" {
  count   = min(var.haproxy_external_node_count, 1)
  name    = "${var.prefix}-gitlab-rails-ssh"
  network = local.vpc_name

  description = "Allow access to GitLab SSH via external load balancer for GitLab environment '${var.prefix}' on the ${local.vpc_name} network"

  allow {
    protocol = "tcp"
    ports    = [var.external_ssh_port]
  }

  source_ranges = coalescelist(var.ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  target_tags   = ["${var.prefix}-ssh"]
}

resource "google_compute_firewall" "ssh" {
  name    = "${var.prefix}-ssh"
  network = local.vpc_name

  description = "Allow SSH access for GitLab environment '${var.prefix}' on the ${local.vpc_name} network"

  # kics: Terraform GCP - SSH Access Is Not Restricted - False positive, source CIDR is configurable
  # kics-scan ignore-block
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = coalescelist(var.external_ssh_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  target_tags   = [var.prefix]
}

resource "google_compute_firewall" "icmp" {
  name    = "${var.prefix}-icmp"
  network = local.vpc_name

  description = "Allow ICMP access for GitLab environment '${var.prefix}' on the ${local.vpc_name} network"

  allow {
    protocol = "icmp"
  }

  source_ranges = coalescelist(var.icmp_allowed_ingress_cidr_blocks, var.default_allowed_ingress_cidr_blocks)
  target_tags   = [var.prefix]
}

# Created or Existing network rules
data "google_compute_subnetwork" "selected" {
  count = local.vpc_name != "default" ? 1 : 0

  name = local.subnet_name

  depends_on = [google_compute_subnetwork.gitlab_vpc_subnet[0]]
}

resource "google_compute_firewall" "internal" {
  count   = local.vpc_name != "default" ? 1 : 0
  name    = "${var.prefix}-internal"
  network = local.vpc_name

  description = "Allow internal traffic on the ${local.vpc_name} network"

  # kics: Terraform GCP - RDP Access Is Not Restricted - False positive, source CIDR is locked down
  # kics-scan ignore-block
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  priority      = 65534
  source_ranges = [data.google_compute_subnetwork.selected[0].ip_cidr_range]
}
