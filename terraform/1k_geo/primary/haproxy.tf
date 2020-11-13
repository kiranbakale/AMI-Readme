module "haproxy_external" {
  source = "../../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "haproxy-external"
  node_count = 1

  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
  external_ips = ["${var.external_ip}"]

  geo_site = "${var.geo_site}"
  geo_deployment = "${var.geo_deployment}"

  tags = ["${var.prefix}-web", "${var.prefix}-ssh", "${var.prefix}-haproxy", "${var.prefix}-monitor"]
}

output "haproxy_external" {
  value = module.haproxy_external
}
