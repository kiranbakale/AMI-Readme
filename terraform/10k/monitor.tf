module "monitor" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "monitor"
  node_count = 1

  machine_type = "n1-highcpu-4"

  tags = ["${var.prefix}-web", "${var.prefix}-monitor"]
}

output "monitor" {
  value = module.monitor
}