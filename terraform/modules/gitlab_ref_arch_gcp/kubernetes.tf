locals {
  total_node_pool_count = sum([var.webservice_node_pool_count, var.sidekiq_node_pool_count, var.supporting_node_pool_count])
  node_pool_zones       = var.kubernetes_zones != null ? var.kubernetes_zones : var.zones
  # https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/NodeConfig#mode
  workload_identity_metadata_mode = var.cluster_enable_workload_identity ? "GKE_METADATA" : "MODE_UNSPECIFIED"
}

resource "google_container_cluster" "gitlab_cluster" {
  count = min(local.total_node_pool_count, 1)
  name  = var.prefix

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_shielded_nodes    = true

  network    = local.vpc_name
  subnetwork = local.subnet_name

  # Require VPC Native cluster
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/using_gke_with_terraform#vpc-native-clusters
  # Blank block enables this and picks at random
  ip_allocation_policy {}

  release_channel {
    channel = var.cluster_release_channel
  }

  resource_labels = {
    gitlab_node_prefix = var.prefix
    gitlab_node_type   = "gitlab-cluster"
  }

  node_config {
    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }
  }

  dynamic "workload_identity_config" {
    for_each = range(var.cluster_enable_workload_identity ? 1 : 0)

    content {
      workload_pool = "${var.project}.svc.id.goog"
    }
  }
}

resource "google_container_node_pool" "gitlab_webservice_pool" {
  count          = min(var.webservice_node_pool_count, 1)
  name           = "${var.prefix}-webservice"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_count     = local.node_pool_zones != null ? ceil(var.webservice_node_pool_count / length(local.node_pool_zones)) : var.webservice_node_pool_count
  node_locations = local.node_pool_zones

  node_config {
    machine_type = var.webservice_node_pool_machine_type
    disk_type    = coalesce(var.webservice_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.webservice_node_pool_disk_size, var.default_disk_size)

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    workload_metadata_config {
      mode = local.workload_identity_metadata_mode
    }

    labels = {
      workload = "webservice"
    }
  }
}

resource "google_container_node_pool" "gitlab_sidekiq_pool" {
  count          = min(var.sidekiq_node_pool_count, 1)
  name           = "${var.prefix}-sidekiq"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_count     = local.node_pool_zones != null ? ceil(var.sidekiq_node_pool_count / length(local.node_pool_zones)) : var.sidekiq_node_pool_count
  node_locations = local.node_pool_zones

  node_config {
    machine_type = var.sidekiq_node_pool_machine_type
    disk_type    = coalesce(var.sidekiq_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.sidekiq_node_pool_disk_size, var.default_disk_size)

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    workload_metadata_config {
      mode = local.workload_identity_metadata_mode
    }

    labels = {
      workload = "sidekiq"
    }
  }
}

resource "google_container_node_pool" "gitlab_supporting_pool" {
  count          = min(var.supporting_node_pool_count, 1)
  name           = "${var.prefix}-supporting"
  cluster        = google_container_cluster.gitlab_cluster[0].name
  node_count     = local.node_pool_zones != null ? ceil(var.supporting_node_pool_count / length(local.node_pool_zones)) : var.supporting_node_pool_count
  node_locations = local.node_pool_zones

  node_config {
    machine_type = var.supporting_node_pool_machine_type
    disk_type    = coalesce(var.supporting_node_pool_disk_type, var.default_disk_type)
    disk_size_gb = coalesce(var.supporting_node_pool_disk_size, var.default_disk_size)

    shielded_instance_config {
      enable_secure_boot = var.machine_secure_boot
    }

    workload_metadata_config {
      mode = local.workload_identity_metadata_mode
    }

    labels = {
      workload = "support"
    }
  }
}

resource "google_compute_firewall" "gitlab_kubernetes_vms_internal" {
  name    = "${var.prefix}-kubernetes-vms-internal"
  network = local.vpc_name
  count   = min(local.total_node_pool_count, 1)

  description = "Allow internal access between GitLab Kubernetes containers and VMs"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  source_ranges = [google_container_cluster.gitlab_cluster[count.index].cluster_ipv4_cidr]
}
