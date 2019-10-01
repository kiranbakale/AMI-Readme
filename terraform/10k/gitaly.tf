module "gitaly" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitaly"
  node_count = 2

  machine_type = "custom-16-61440"
  label_secondaries = true
}

output "gitaly" {
  value = module.gitaly
}