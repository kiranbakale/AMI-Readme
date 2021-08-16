module "gitlab_rails" {
  source = "../gitlab_gcp_instance"

  prefix = var.prefix
  node_type = "gitlab-rails"
  node_count = var.gitlab_rails_node_count

  machine_type = var.gitlab_rails_machine_type
  machine_image = var.machine_image
  disk_size = coalesce(var.gitlab_rails_disk_size, var.default_disk_size)
  disk_type = coalesce(var.gitlab_rails_disk_type, var.default_disk_type)

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
  disks = var.gitlab_rails_disks
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
