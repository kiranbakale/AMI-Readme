module "elastic" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "elastic"
  node_count = 2

  disk_type = "pd-ssd"
  disk_size = "500"

  machine_type = "n1-highcpu-8"
  machine_image = "${var.machine_image}"
  label_secondaries = true
}

output "elastic" {
  value = module.elastic
}