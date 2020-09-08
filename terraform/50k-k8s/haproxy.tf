module "haproxy_internal" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "haproxy-internal"
  node_count = 1
  
  machine_type = "n1-highcpu-8"
  machine_image = "${var.machine_image}"

  tags = ["${var.prefix}-haproxy"]
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
