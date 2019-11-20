module "pgbouncer" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "pgbouncer"
  node_count = 3

  machine_type = "n1-highcpu-2"
  machine_image = "${var.machine_image}"
}

output "pgbouncer" {
  value = module.pgbouncer
}
