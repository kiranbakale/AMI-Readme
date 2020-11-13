module "monitor" {
  source = "../../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "monitor"
  node_count = 1

  geo_site = "${var.geo_site}"
  geo_deployment = "${var.geo_deployment}"

  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
}

output "monitor" {
  value = module.monitor
}
