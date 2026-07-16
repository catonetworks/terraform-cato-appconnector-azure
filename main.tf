###############################################################################
# Locals
###############################################################################

locals {
  clean_ac_name           = regex("^[a-z][-a-z0-9]{0,61}[a-z0-9]?$", replace(lower(var.app_connector_name), "_", "-"))
  effective_rg_name       = var.resource_group_name == null ? azurerm_resource_group.this[0].name : var.resource_group_name
  effective_vnet_name     = var.vnet_name == null ? azurerm_virtual_network.this[0].name : var.vnet_name
  effective_lan_subnet_id = var.lan_subnet_id == null ? azurerm_subnet.lan[0].id : var.lan_subnet_id
}

###############################################################################
# Resource Group (conditional — create if resource_group_name is null)
###############################################################################

resource "azurerm_resource_group" "this" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

###############################################################################
# Virtual Network + Subnets (mgmt / wan / lan)
###############################################################################

resource "azurerm_virtual_network" "this" {
  count               = var.vnet_name == null ? 1 : 0
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = local.effective_rg_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
  depends_on          = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "mgmt" {
  name                 = "${var.prefix}-mgmt-subnet"
  resource_group_name  = local.effective_rg_name
  virtual_network_name = local.effective_vnet_name
  address_prefixes     = [var.mgmt_subnet_cidr]
  depends_on           = [azurerm_virtual_network.this]
}

resource "azurerm_subnet" "wan" {
  name                 = "${var.prefix}-wan-subnet"
  resource_group_name  = local.effective_rg_name
  virtual_network_name = local.effective_vnet_name
  address_prefixes     = [var.wan_subnet_cidr]
  depends_on           = [azurerm_virtual_network.this]
}

resource "azurerm_subnet" "lan" {
  count                = var.lan_subnet_id == null ? 1 : 0
  name                 = "${var.prefix}-lan-subnet"
  resource_group_name  = local.effective_rg_name
  virtual_network_name = local.effective_vnet_name
  address_prefixes     = [var.lan_subnet_cidr]
  depends_on           = [azurerm_virtual_network.this]
}

###############################################################################
# Network Security Group
###############################################################################

resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = local.effective_rg_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.ssh_allowed_cidr == null ? [] : [var.ssh_allowed_cidr]
    content {
      name                       = "allow-ssh-mgmt"
      priority                   = 1000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.sg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "wan" {
  subnet_id                 = azurerm_subnet.wan.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "lan" {
  count                     = var.lan_subnet_id == null ? 1 : 0
  subnet_id                 = azurerm_subnet.lan[0].id
  network_security_group_id = azurerm_network_security_group.this.id
}

###############################################################################
# Public IP (WAN egress to the Cato PoP)
###############################################################################

resource "azurerm_public_ip" "wan" {
  name                = "${var.prefix}-wan-pip"
  location            = var.location
  resource_group_name = local.effective_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
  depends_on          = [azurerm_resource_group.this]
}

###############################################################################
# Network Interfaces (mgmt / wan / lan)
###############################################################################

resource "azurerm_network_interface" "mgmt" {
  name                = "${var.prefix}-mgmt-nic"
  location            = var.location
  resource_group_name = local.effective_rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet.mgmt]
}

resource "azurerm_network_interface" "wan" {
  name                = "${var.prefix}-wan-nic"
  location            = var.location
  resource_group_name = local.effective_rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.wan.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan.id
  }

  depends_on = [azurerm_subnet.wan, azurerm_public_ip.wan]
}

resource "azurerm_network_interface" "lan" {
  name                  = "${var.prefix}-lan-nic"
  location              = var.location
  resource_group_name   = local.effective_rg_name
  ip_forwarding_enabled = true
  tags                  = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = local.effective_lan_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

###############################################################################
# Marketplace Image Terms
###############################################################################

resource "azurerm_marketplace_agreement" "cato" {
  count = var.accept_marketplace_terms ? 1 : 0

  publisher = var.image_publisher
  offer     = var.image_offer
  plan      = var.image_sku
}

###############################################################################
# Cato App Connector — registers the connector in the Cato Management App
###############################################################################

resource "cato_app_connector" "this" {
  name        = var.app_connector_name
  description = var.app_connector_description
  group_name  = var.app_connector_group
  location    = local.cur_site_location
  preferred_pop_location = {
    automatic      = false
    preferred_only = true
    primary        = var.app_connector_primary_pop != null ? { name = var.app_connector_primary_pop } : null
    secondary      = var.app_connector_secondary_pop != null ? { name = var.app_connector_secondary_pop } : null
  }
  type = "VIRTUAL"
}
