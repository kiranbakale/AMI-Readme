output "instance_ids" {
  value = aws_instance.gitlab[*].id
}

output "external_addresses" {
  value = aws_instance.gitlab[*].public_ip
}

output "internal_addresses" {
  value = aws_instance.gitlab[*].private_ip
}

output "data_disk_device_names" {
  value = [for k, v in aws_volume_attachment.gitlab : "${k} = ${v.device_name}"]
}
