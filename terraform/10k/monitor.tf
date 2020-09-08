module "monitor" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "monitor"
  node_count = 1

  machine_type = "n1-highcpu-4"
  machine_image = "${var.machine_image}"
}

output "monitor" {
  value = module.monitor
}