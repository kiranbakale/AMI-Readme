module "gce-lb-fr" {
  source       = "GoogleCloudPlatform/lb/google"
  region       = "${var.region}"
  name         = "${var.prefix}-lb"
  service_port = "80"
  target_tags  = ["${var.prefix}-web"]
}

output "load-balancer-ip" {
  value = "${module.gce-lb-fr.external_ip}"
}