resource "google_storage_bucket" "gitlab" {
  name = "${var.prefix}-${var.storage_type}-storage"
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "gitlab_binding" {
  bucket = google_storage_bucket.gitlab.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}
