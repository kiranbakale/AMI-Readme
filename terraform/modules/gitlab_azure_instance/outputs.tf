output "machine_names" {
  value = azurerm_linux_virtual_machine.gitlab[*].name
}

output "internal_addresses" {
  value = azurerm_linux_virtual_machine.gitlab[*].private_ip_address
}

output "external_addresses" {
  value = azurerm_linux_virtual_machine.gitlab[*].public_ip_address
}

output "virtual_machine_ids" {
  value = azurerm_linux_virtual_machine.gitlab[*].virtual_machine_id
}
