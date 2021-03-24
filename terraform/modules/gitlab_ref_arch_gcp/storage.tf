# Legacy Object Storage config - To be deprecated
resource "google_storage_bucket" "gitlab_object_storage" {
  count = length(var.object_storage_buckets) == 1 ? 1 : 0
  name = "${var.prefix}-${var.object_storage_buckets[0]}"
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_binding" {
  count = length(var.object_storage_buckets) == 1 ? 1 : 0
  bucket = google_storage_bucket.gitlab_object_storage[count.index].name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}

# Current Object Storage config
resource "google_storage_bucket" "gitlab_object_storage_buckets" {
  for_each = toset(length(var.object_storage_buckets) == 1 ? [] : var.object_storage_buckets)
  name = "${var.prefix}-${each.value}"
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_buckets_binding" {
  for_each = google_storage_bucket.gitlab_object_storage_buckets
  bucket = each.value.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}
