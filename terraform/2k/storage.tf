resource "google_storage_bucket" "gitlab_secrets_storage" {
  name = "${var.prefix}-secrets-storage"
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "gitlab_secrets_storage_binding" {
  bucket = google_storage_bucket.gitlab_secrets_storage.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}

resource "google_storage_bucket_object" "serviceaccount" {
  name = "serviceaccount.json"
  source = var.credentials_file
  bucket = google_storage_bucket.gitlab_secrets_storage.name
}

resource "google_storage_bucket" "gitlab_object_storage" {
  name = "${var.prefix}-object-storage"
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "gitlab_object_storage_binding" {
  bucket = google_storage_bucket.gitlab_object_storage.name
  role = "roles/storage.objectAdmin"

  members = [
    "projectEditor:${var.project}",
  ]
}

