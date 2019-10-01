module "consul" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "consul"
  node_count = 3

  machine_type = "n1-highcpu-2"
}

output "consul" {
  value = module.consul
}