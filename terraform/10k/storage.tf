resource "google_storage_bucket" "gitlab" {
  name = "gitlab-conf-storage"
  force_destroy = true
}
