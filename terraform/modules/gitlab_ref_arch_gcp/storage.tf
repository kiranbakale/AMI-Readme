resource "google_storage_bucket" "gitlab_object_storage_buckets" {
  for_each = toset(var.object_storage_buckets)

  name          = "${var.prefix}-${each.value}"
  location      = var.object_storage_location
  force_destroy = var.object_storage_force_destroy

  uniform_bucket_level_access = true

  labels = var.object_storage_labels
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_buckets_binding" {
  for_each = google_storage_bucket.gitlab_object_storage_buckets
  bucket   = each.value.name
  role     = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}
