resource "google_storage_bucket" "gitlab" {
  name = "${var.prefix}-conf-storage"
  force_destroy = true
}