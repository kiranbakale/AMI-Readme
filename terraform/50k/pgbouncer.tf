module "pgbouncer" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "pgbouncer"
  node_count = 3

  # machine_type = "custom-2-4096"
  machine_type = "n1-highcpu-2"
}

output "pgbouncer" {
  value = module.pgbouncer
}
