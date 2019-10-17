module "gitaly" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitaly"
  node_count = 4

  disk_type = "pd-ssd"

  # machine_type = "custom-64-184320"
  # machine_type = "n1-standard-64"
  machine_type = "n1-highcpu-64"
  label_secondaries = true
}

output "gitaly" {
  value = module.gitaly
}