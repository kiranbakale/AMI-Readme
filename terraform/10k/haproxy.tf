module "haproxy_external" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "haproxy-external"
  node_count = 1
  
  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
  external_ips = ["34.73.165.75"]

  tags = ["${var.prefix}-web", "${var.prefix}-ssh", "${var.prefix}-haproxy", "${var.prefix}-monitor"]
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "haproxy-internal"
  node_count = 1
  
  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"

  tags = ["${var.prefix}-haproxy"]
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
