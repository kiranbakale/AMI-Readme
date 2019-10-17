resource "google_storage_bucket" "gitlab" {
  name = "${var.prefix}-conf-storage"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_object_storage" {
  name = "${var.prefix}-object-storage"
  force_destroy = true
}
