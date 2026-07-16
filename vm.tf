###############################################################################
# Post-creation MAC address lookups (MAC only available after VM is created)
###############################################################################

data "azurerm_network_interface" "wan-mac" {
  name                = azurerm_network_interface.wan.name
  resource_group_name = local.effective_rg_name
  depends_on          = [azurerm_linux_virtual_machine.app_connector]
}

data "azurerm_network_interface" "lan-mac" {
  name                = azurerm_network_interface.lan.name
  resource_group_name = local.effective_rg_name
  depends_on          = [azurerm_linux_virtual_machine.app_connector]
}

###############################################################################
# Random credentials (app_connector does not allow auth but instance requires it)
###############################################################################

resource "random_string" "app_connector_random_username" {
  length  = 16
  special = false
}

resource "random_string" "app_connector_random_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

###############################################################################
# App Connector Virtual Machine
###############################################################################

resource "azurerm_linux_virtual_machine" "app_connector" {
  depends_on = [
    cato_app_connector.this,
    azurerm_network_interface.mgmt,
    azurerm_network_interface.wan,
    azurerm_network_interface.lan,
    azurerm_marketplace_agreement.cato,
  ]

  location            = var.location
  name                = var.app_connector_vm_name
  computer_name       = local.clean_ac_name
  resource_group_name = local.effective_rg_name
  size                = var.vm_size
  network_interface_ids = [
    azurerm_network_interface.mgmt.id,
    azurerm_network_interface.lan.id,
    azurerm_network_interface.wan.id
  ]
  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true
  admin_username                  = random_string.app_connector_random_username.result
  admin_password                  = "${random_string.app_connector_random_password.result}@"

  boot_diagnostics {
    storage_account_uri = ""
  }

  os_disk {
    name                 = var.app_connector_disk_name
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.disk_size_gb
  }

  plan {
    name      = var.image_sku
    publisher = var.image_publisher
    product   = var.image_offer
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = base64encode(jsonencode({
    "cato-serial-id" = cato_app_connector.this.serial_number
  }))

  tags = var.tags
}

###############################################################################
# Custom Script Extension — configure NIC mapping + start daemon
###############################################################################

resource "azurerm_virtual_machine_extension" "app_connector_custom_script" {
  auto_upgrade_minor_version = true
  name                       = "app_connector_custom_script"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.app_connector.id
  lifecycle {
    ignore_changes = all
  }

  settings   = <<SETTINGS
  {
  "commandToExecute": "echo '{\"wan_ip\" : \"${azurerm_network_interface.wan.private_ip_address}\", \"wan_name\" : \"${azurerm_network_interface.wan.name}\", \"wan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.wan-mac.mac_address, "-", ":"))}\", \"lan_ip\" : \"${azurerm_network_interface.lan.private_ip_address}\", \"lan_name\" : \"${azurerm_network_interface.lan.name}\", \"lan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.lan-mac.mac_address, "-", ":"))}\"}' > /cato/nics_config.json; echo '${cato_app_connector.this.serial_number}' > /cato/serial.txt;${join(";", var.commands)}"
  }
  SETTINGS
  depends_on = [azurerm_network_interface.lan, azurerm_network_interface.wan, azurerm_network_interface.mgmt]
}
