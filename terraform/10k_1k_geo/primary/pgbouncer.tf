module "pgbouncer" {
  source = "../../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "pgbouncer"
  node_count = 3

  geo_site = "${var.geo_site}"
  geo_deployment = "${var.geo_deployment}"

  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
}

output "pgbouncer" {
  value = module.pgbouncer
}
