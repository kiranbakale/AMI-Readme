module "postgres" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "postgres"
  node_count = 3

  machine_type = "n1-standard-8"
  machine_image = "${var.machine_image}"
  label_secondaries = true
}

output "postgres" {
  value = module.postgres
}
