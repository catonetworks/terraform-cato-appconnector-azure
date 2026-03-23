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
  depends_on = [cato_app_connector.this]

  location            = var.location
  name                = var.app_connector_vm_name
  computer_name       = local.clean_ac_name
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  network_interface_ids = [
    var.mgmt_nic_id,
    var.lan_nic_id,
    var.wan_nic_id
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


