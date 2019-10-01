module "gitlab-nfs" {
  source = "../modules/gitlab_gcp_instance"

  prefix = "${var.prefix}"
  node_type = "gitlab-nfs"
  node_count = 1

  machine_type = "n1-standard-4"
}

output "gitlab_nfs" {
  value = module.gitlab-nfs
}
