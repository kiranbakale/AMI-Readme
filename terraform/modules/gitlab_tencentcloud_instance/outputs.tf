output "ecs_public_ip" {
  value = join(",", tencentcloud_instance.gitlab.*.public_ip)
}

output "ecs_private_ip" {
  value = join(",", tencentcloud_instance.gitlab.*.private_ip)
}
