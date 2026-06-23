data "azurerm_network_interface" "mgmt" {
  name                = var.mgmt_nic_name
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "wan" {
  name                = var.wan_nic_name
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "lan" {
  name                = var.lan_nic_name
  resource_group_name = var.resource_group_name
}

data "azurerm_network_interface" "wan-mac" {
  name                = var.wan_nic_name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.app_connector]
}

data "azurerm_network_interface" "lan-mac" {
  name                = var.lan_nic_name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_linux_virtual_machine.app_connector]
}


## Create random strings for auth, as the app_connector does not allow auth but the instance requires it
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

## Create app_connector Virtual Machine
resource "azurerm_linux_virtual_machine" "app_connector" {
  depends_on = [cato_app_connector.this, data.azurerm_network_interface.lan, data.azurerm_network_interface.wan, data.azurerm_network_interface.mgmt]

  location            = var.location
  name                = var.app_connector_vm_name
  computer_name       = local.clean_ac_name
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  network_interface_ids = [
    data.azurerm_network_interface.mgmt.id,
    data.azurerm_network_interface.lan.id,
    data.azurerm_network_interface.wan.id
  ]
  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true
  admin_username                  = random_string.app_connector_random_username.result
  admin_password                  = "${random_string.app_connector_random_password.result}@"

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = "" # Empty string enables boot diagnostics
  }

  # OS disk configuration from image
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

  # Custom metadata with serial id
  custom_data = base64encode(jsonencode({
    "cato-serial-id" = cato_app_connector.this.serial_number
  }))


  tags = var.tags
}



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
  "commandToExecute": "echo '{\"wan_ip\" : \"${data.azurerm_network_interface.wan.private_ip_address}\", \"wan_name\" : \"${data.azurerm_network_interface.wan.name}\", \"wan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.wan-mac.mac_address, "-", ":"))}\", \"lan_ip\" : \"${data.azurerm_network_interface.lan.private_ip_address}\", \"lan_name\" : \"${data.azurerm_network_interface.lan.name}\", \"lan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.lan-mac.mac_address, "-", ":"))}\"}' > /cato/nics_config.json; echo '${cato_app_connector.this.serial_number}' > /cato/serial.txt;${join(";", var.commands)}"
  }
  SETTINGS
  depends_on = [data.azurerm_network_interface.lan, data.azurerm_network_interface.wan, data.azurerm_network_interface.mgmt]
}
