###############################################################################
# Azure Infrastructure Outputs
###############################################################################

output "resource_group_name" {
  description = "Resource group containing the App Connector."
  value       = local.effective_rg_name
}

output "azurerm_virtual_network_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "wan_public_ip" {
  description = "Public IP address assigned to the WAN interface."
  value       = azurerm_public_ip.wan.ip_address
}

output "wan_public_ip_id" {
  description = "ID of the WAN public IP resource."
  value       = azurerm_public_ip.wan.id
}

output "mgmt_nic_id" {
  description = "ID of the management NIC."
  value       = azurerm_network_interface.mgmt.id
}

output "wan_nic_id" {
  description = "ID of the WAN NIC."
  value       = azurerm_network_interface.wan.id
}

output "lan_nic_id" {
  description = "ID of the LAN NIC."
  value       = azurerm_network_interface.lan.id
}

output "mgmt_subnet_id" {
  description = "ID of the management subnet."
  value       = azurerm_subnet.mgmt.id
}

output "wan_subnet_id" {
  description = "ID of the WAN subnet."
  value       = azurerm_subnet.wan.id
}

output "lan_subnet_id" {
  description = "ID of the LAN subnet."
  value       = azurerm_subnet.lan.id
}

output "nsg_id" {
  description = "ID of the network security group."
  value       = azurerm_network_security_group.this.id
}

###############################################################################
# Cato App Connector Outputs
###############################################################################

output "cato_appconnector_id" {
  description = "ID of the Cato AppConnector"
  value       = cato_app_connector.this.id
}

output "cato_appconnector_name" {
  description = "Name of the Cato AppConnector"
  value       = cato_app_connector.this.name
}

output "cato_serial_id" {
  description = "Serial ID of the Cato AppConnector"
  value       = try(cato_app_connector.this.serial_number, "N/A")
}

###############################################################################
# VM Outputs
###############################################################################

output "boot_disk_name" {
  description = "Boot disk name for the VM"
  value       = azurerm_linux_virtual_machine.app_connector.os_disk[0].name
}

output "vm_instance_name" {
  description = "Name of the VM instance"
  value       = azurerm_linux_virtual_machine.app_connector.name
}

output "vm_instance_id" {
  description = "ID of the VM instance"
  value       = azurerm_linux_virtual_machine.app_connector.id
}

output "vm_location" {
  description = "Azure region of the VM"
  value       = azurerm_linux_virtual_machine.app_connector.location
}

output "vm_size" {
  description = "Size of the VM"
  value       = azurerm_linux_virtual_machine.app_connector.size
}

output "vm_private_ip_address" {
  description = "Primary private IP address of the VM"
  value       = try(azurerm_linux_virtual_machine.app_connector.private_ip_address, null)
}

output "vm_private_ip_addresses" {
  description = "Private IP addresses of the VM"
  value       = try(azurerm_linux_virtual_machine.app_connector.private_ip_addresses, [])
}

output "vm_public_ip_address" {
  description = "Primary public IP address of the VM if assigned"
  value       = try(azurerm_linux_virtual_machine.app_connector.public_ip_address, null)
}

output "vm_network_interface_ids" {
  description = "Network interface IDs attached to the VM"
  value       = azurerm_linux_virtual_machine.app_connector.network_interface_ids
}

output "vm_tags" {
  description = "Tags assigned to the VM"
  value       = azurerm_linux_virtual_machine.app_connector.tags
}
