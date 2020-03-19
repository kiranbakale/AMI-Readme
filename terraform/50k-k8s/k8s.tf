resource "google_container_cluster" "gitlab_cluster" {
  name     = "gitlab-cluster"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  
  ip_allocation_policy {}

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_compute_firewall" "gitlab_cluster" {
  name    = "${var.prefix}-gitlab-cluster-firewall-rule"
  network = "default"

  description = "Allow k8s cluster pods to access Compute VMs on same network"

  allow {
    protocol = "all"
  }

  source_ranges = [google_container_cluster.gitlab_cluster.cluster_ipv4_cidr]
}

resource "google_container_node_pool" "gitlab_node_pool" {
  name       = "gitlab-node-pool"
  cluster    = google_container_cluster.gitlab_cluster.name

  autoscaling {
    min_node_count = 1
    max_node_count = 12
  }

  node_config {
    machine_type = "n1-highcpu-32"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}