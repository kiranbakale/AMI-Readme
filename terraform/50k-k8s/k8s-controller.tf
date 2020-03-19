module "k8s_controller" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "k8s-controller"
  node_count = 1

  machine_type = "g1-small"
  machine_image = "${var.machine_image}"

  scopes = ["userinfo-email", "cloud-platform"]
}

output "k8s_controller" {
  value = module.k8s_controller
} 