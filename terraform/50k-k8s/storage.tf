# LFS Bucket
module "gitlab_lfs_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "lfs"
}

# Artifacts Bucket
module "gitlab_artifacts_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "artifacts"
}

# Uploads Bucket
module "gitlab_uploads_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "uploads"
}

# Packages Bucket
module "gitlab_packages_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "packages"
}

# External Diffs Bucket
module "gitlab_external_diffs_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "external-diffs"
}

# Registry Bucket
module "gitlab_registry_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "registry"
}

# Backups Buckets
module "gitlab_backups_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "backups"
}

module "gitlab_backups_tmp_storage" {
  source = "../modules/gitlab_gcp_storage_bucket"

  prefix = "${var.prefix}"
  project = "${var.project}"

  storage_type = "backups-tmp"
}
