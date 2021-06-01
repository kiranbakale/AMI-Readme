resource "tencentcloud_subnet" "k8s_subnet" {
  name              = "${var.prefix}-k8s-subnet"
  vpc_id            = tencentcloud_vpc.vpc.id
  cidr_block        = var.k8s_subnet_cidr
  availability_zone = data.tencentcloud_availability_zones.zones_ds.zones.0.name
}

resource "tencentcloud_kubernetes_cluster" "k8s" {
  vpc_id                                     = tencentcloud_vpc.vpc.id
  cluster_cidr                               = var.k8s_cluster_cidr
  cluster_max_pod_num                        = 32
  cluster_name                               = "${var.prefix}-cluster"
  cluster_desc                               = "${var.prefix}-cluster"
  cluster_max_service_num                    = 32
  cluster_internet                           = true
  managed_cluster_internet_security_policies = ["3.3.3.3", "1.1.1.1"]
  cluster_deploy_type                        = "MANAGED_CLUSTER"
  cluster_os                                 = var.k8s_cluster_os
  cluster_version                            = var.k8s_cluster_version

  worker_config {
    count                      = var.k8s_worker_number
    availability_zone          = data.tencentcloud_availability_zones.zones_ds.zones.0.name
    instance_type              = var.default_instance_type
    system_disk_type           = var.default_disk_type
    system_disk_size           = var.default_disk_size
    internet_charge_type       = "TRAFFIC_POSTPAID_BY_HOUR"
    internet_max_bandwidth_out = 100
    public_ip_assigned         = true
    subnet_id                  = tencentcloud_subnet.k8s_subnet.id

    enhanced_security_service = true
    enhanced_monitor_service  = true
    password                  = var.k8s_worker_password
  }
}
