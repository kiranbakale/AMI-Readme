output "external_addresses" {
  value = aws_instance.gitlab[*].public_ip
}
