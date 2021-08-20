output "machine_names" {
  value = google_compute_instance.gitlab[*].name
}

output "internal_addresses" {
  value = google_compute_instance.gitlab[*].network_interface[0].network_ip
}

output "external_addresses" {
  value = var.setup_external_ip ? google_compute_instance.gitlab[*].network_interface[0].access_config[0].nat_ip : []
}

output "self_links" {
  value = google_compute_instance.gitlab[*].self_link
}
