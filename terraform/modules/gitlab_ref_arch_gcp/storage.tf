# Legacy Object Storage config - To be deprecated
resource "google_storage_bucket" "gitlab_object_storage" {
  name = "${var.prefix}-object-storage"
  force_destroy = var.object_storage_buckets_force_destroy
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_binding" {
  bucket = google_storage_bucket.gitlab_object_storage.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}

# Current Object Storage config
resource "google_storage_bucket" "gitlab_object_storage_buckets" {
  for_each = toset(var.object_storage_buckets)
  name = "${var.prefix}-${each.value}"
  force_destroy = var.object_storage_buckets_force_destroy
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_buckets_binding" {
  for_each = google_storage_bucket.gitlab_object_storage_buckets
  bucket = each.value.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}
