## Azure Variables

variable "location" {
  description = "(Required) The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created."
  type        = string
}

variable "prefix" {
  description = "Name prefix applied to all created resources."
  type        = string
  default     = "cato-appconn"
}

variable "resource_group_name" {
  description = "Azure resource group name. If null, a new resource group will be created."
  type        = string
  default     = null
}

variable "tags" {
  description = "A Map of Keys and Values to Describe the infrastructure"
  type        = map(any)
  default     = null
}

## Networking Variables

variable "vnet_name" {
  description = "Name of an existing VNet to deploy into. If null, a new VNet is created."
  type        = string
  default     = null
}

variable "vnet_cidr" {
  description = "Address space for the VNet. Only used when creating a new VNet (vnet_name is null)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "mgmt_subnet_cidr" {
  description = "CIDR for the management subnet."
  type        = string
  default     = "10.20.0.0/24"
}

variable "wan_subnet_cidr" {
  description = "CIDR for the WAN subnet (egress to Cato PoP)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "lan_subnet_cidr" {
  description = "CIDR for the LAN subnet (faces the protected application network). Only used when lan_subnet_id is null."
  type        = string
  default     = "10.20.2.0/24"
}

variable "lan_subnet_id" {
  description = "ID of an existing subnet for the LAN NIC. If null, a new LAN subnet is created using lan_subnet_cidr."
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "Optional source CIDR allowed to SSH to the mgmt NIC for troubleshooting. Null disables the inbound SSH rule."
  type        = string
  default     = null
}

variable "sg_rules" {
  description = "Security rules for the Network Security Group"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

## VM Variables

variable "vm_size" {
  description = "(Required) Specifies the size of the Virtual Machine. See also Azure VM Naming Conventions. https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions"
  default     = "Standard_D8ls_v5"
  type        = string
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB"
  default     = 8
  validation {
    condition     = var.disk_size_gb > 0
    error_message = "Disk size must be greater than 0"
  }
}

variable "storage_account_type" {
  type        = string
  description = "Storage account type"
  default     = "Standard_LRS"
  validation {
    condition     = var.storage_account_type == "Standard_LRS" || var.storage_account_type == "StandardSSD_ZRS" || var.storage_account_type == "Premium_LRS" || var.storage_account_type == "PremiumV2_LRS" || var.storage_account_type == "Premium_ZRS" || var.storage_account_type == "StandardSSD_LRS" || var.storage_account_type == "UltraSSD_LRS"
    error_message = "Storage account type must be one of: Standard_LRS, StandardSSD_ZRS, Premium_LRS, PremiumV2_LRS, Premium_ZRS, StandardSSD_LRS or UltraSSD_LRS"
  }
}

## Marketplace Image Variables

variable "image_publisher" {
  description = "Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "catonetworks"
}

variable "image_offer" {
  description = "Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "catoappconnector"
}

variable "image_sku" {
  description = "Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "appconnector"
}

variable "image_version" {
  description = "Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created."
  type        = string
  default     = "23.0.19605"
}

variable "accept_marketplace_terms" {
  description = "Whether Terraform should accept the Cato marketplace image terms. Set to false if the terms are already accepted on this subscription."
  type        = bool
  default     = true
}

## App Connector Variables

variable "app_connector_name" {
  type        = string
  description = "Name of the app-connector virtual machine"
  default     = "app-connector"
}

variable "app_connector_disk_name" {
  description = "Cato App Connector Disk name"
  type        = string
  default     = "Cato-app-connector-disk"
}

variable "app_connector_vm_name" {
  description = "Azure Cato App Connector name"
  type        = string
  default     = "Cato-app-connector"
}

variable "app_connector_description" {
  description = "AppConnector description"
  type        = string
  default     = null
}

variable "app_connector_group" {
  description = "AppConnector group name"
  type        = string
}

variable "app_connector_primary_pop" {
  description = "Primary POP location (state) for the AppConnector"
  type        = string
  default     = null
}

variable "app_connector_secondary_pop" {
  description = "Secondary POP location (state) for the AppConnector"
  type        = string
  default     = null
}

variable "commands" {
  type = list(string)
  default = [
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

variable "site_location" {
  description = "Site location which is used by the Cato App Connector to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamically."
  type = object({
    city_name    = string
    country_code = string
    state_code   = string
    timezone     = string
  })
  default = {
    city_name    = null
    country_code = null
    state_code   = null ## Optional - for countries with states
    timezone     = null
  }
}
