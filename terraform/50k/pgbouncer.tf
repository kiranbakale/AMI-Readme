module "pgbouncer" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "pgbouncer"
  node_count = 1

  machine_type = "custom-2-4096"
}

output "pgbouncer" {
  value = module.pgbouncer
}
