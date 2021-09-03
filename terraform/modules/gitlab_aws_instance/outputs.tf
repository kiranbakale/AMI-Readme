output "instance_ids" {
  value = aws_instance.gitlab[*].id
}

output "external_addresses" {
  value = aws_instance.gitlab[*].public_ip
}

output "internal_addresses" {
  value = aws_instance.gitlab[*].private_ip
}