output "ecs_public_ip" {
  value = join(",", alicloud_instance.gitlab.*.public_ip)
}

output "ecs_private_ip" {
  value = join(",", alicloud_instance.gitlab.*.private_ip)
}
