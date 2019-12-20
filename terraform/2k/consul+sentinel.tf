module "consul_sentinel" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "consul-sentinel"
  node_count = 3

  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
}

output "consul_sentinel" {
  value = module.consul_sentinel
}