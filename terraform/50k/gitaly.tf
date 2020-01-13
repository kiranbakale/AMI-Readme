module "gitaly" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitaly"
  node_count = 4

  disk_type = "pd-ssd"
  disk_size = "500"

  machine_type = "n1-highcpu-64"
  machine_image = "${var.machine_image}"
  label_secondaries = true
}

output "gitaly" {
  value = module.gitaly
}