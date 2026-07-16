# Cato Networks Azure App Connector Terraform Module

This module deploys a Cato Networks App Connector on Azure with all required networking infrastructure embedded. The module creates the VNet, subnets, NSG, NICs, public IP, and the App Connector VM — no external resource creation needed.

The design follows the same pattern as the `catonetworks/vsocket-azure-vnet/cato` module: resources are created natively within the module, with conditional logic to create a new resource group or use an existing one.

- *Note: This feature is currently in Early Availability (EA) and has been rolled out to a limited set of customer accounts for testing and validation purposes.*

## Pre-reqs

- Install the [Azure Cloud CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Run `az login` to configure the Azure CLI
- A Cato Networks account with API access

## Usage

### Minimal Example (Greenfield)

Creates all resources from scratch — resource group, VNet, subnets, NSG, NICs, and the App Connector VM. Site location is automatically derived from the Azure region.

```hcl
provider "azurerm" {
  features {}
}

provider "cato" {
  baseurl    = "https://api.catonetworks.com/api/v1/graphql2"
  token      = var.cato_token
  account_id = var.cato_account_id
}

module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location = "eastus"
  prefix   = "my-appconn"

  app_connector_name        = "appconn-eastus"
  app_connector_description = "Azure App Connector - East US"
  app_connector_group       = "azure-app-connectors"
  app_connector_primary_pop = "New York"

  tags = {
    environment = "production"
    owner       = "a.u.thor@example.com"
  }
}
```

### Custom Networking

Override the default VNet and subnet CIDRs, add SSH access for troubleshooting, and specify a secondary PoP.

```hcl
module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location = "westus2"
  prefix   = "prod-appconn"

  vnet_cidr        = "10.50.0.0/16"
  mgmt_subnet_cidr = "10.50.0.0/24"
  wan_subnet_cidr  = "10.50.1.0/24"
  lan_subnet_cidr  = "10.50.2.0/24"

  ssh_allowed_cidr = "203.0.113.0/24"

  app_connector_name          = "appconn-westus2"
  app_connector_description   = "West US 2 App Connector"
  app_connector_group         = "azure-west-connectors"
  app_connector_primary_pop   = "Los Angeles"
  app_connector_secondary_pop = "Seattle"

  vm_size      = "Standard_D8ls_v5"
  disk_size_gb = 30

  tags = {
    environment = "production"
    owner       = "a.u.thor@example.com"
  }
}
```

### Existing Resource Group

Deploy into a pre-existing resource group by providing `resource_group_name`. When set, the module skips resource group creation.

```hcl
resource "azurerm_resource_group" "existing" {
  name     = "my-existing-rg"
  location = "eastus"
}

module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location            = azurerm_resource_group.existing.location
  resource_group_name = azurerm_resource_group.existing.name
  prefix              = "shared-appconn"

  app_connector_name        = "appconn-shared"
  app_connector_group       = "shared-connectors"
  app_connector_primary_pop = "New York"
}
```

### Custom NSG Rules

Pass additional security rules via the `sg_rules` variable.

```hcl
module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location = "eastus"
  prefix   = "secure-appconn"

  app_connector_name        = "appconn-secure"
  app_connector_group       = "secure-connectors"
  app_connector_primary_pop = "New York"

  sg_rules = [
    {
      name                       = "Allow-HTTPS-Outbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
    {
      name                       = "Allow-DNS-Outbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = "53"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  ]
}
```

### Custom Site Location

Override the automatic Azure-region-to-location mapping with explicit site location values.

```hcl
module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location = "eastus"
  prefix   = "custom-loc-appconn"

  app_connector_name        = "appconn-custom-loc"
  app_connector_group       = "custom-connectors"
  app_connector_primary_pop = "New York"

  site_location = {
    city_name    = "Ashburn"
    country_code = "US"
    state_code   = "US-VA"
    timezone     = "America/New_York"
  }
}
```

### Skip Marketplace Terms

If the Cato marketplace terms have already been accepted on your subscription, set `accept_marketplace_terms = false` to avoid errors.

```hcl
module "app_connector" {
  source = "catonetworks/appconnector-azure/cato"

  location = "eastus"
  prefix   = "appconn"

  accept_marketplace_terms = false

  app_connector_name        = "appconn-eastus"
  app_connector_group       = "azure-connectors"
  app_connector_primary_pop = "New York"
}
```

## Resources Created

This module creates the following Azure resources:

| Resource | Description |
|----------|-------------|
| `azurerm_resource_group` | Resource group (conditional — skipped when `resource_group_name` is provided) |
| `azurerm_virtual_network` | VNet with configurable address space |
| `azurerm_subnet` (x3) | Management, WAN, and LAN subnets |
| `azurerm_network_security_group` | NSG with optional SSH and custom rules |
| `azurerm_subnet_network_security_group_association` (x3) | NSG associations for each subnet |
| `azurerm_public_ip` | Static public IP for WAN egress |
| `azurerm_network_interface` (x3) | Management, WAN (with public IP), and LAN (with IP forwarding) NICs |
| `azurerm_marketplace_agreement` | Marketplace terms acceptance (conditional) |
| `azurerm_linux_virtual_machine` | App Connector VM |
| `azurerm_virtual_machine_extension` | Custom script for NIC configuration and daemon startup |
| `cato_app_connector` | App Connector registration in the Cato Management Application |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `location` | Azure region for all resources | `string` | — | yes |
| `prefix` | Name prefix applied to all created resources | `string` | `"cato-appconn"` | no |
| `resource_group_name` | Existing resource group name. Null = create new | `string` | `null` | no |
| `vnet_cidr` | Address space for the VNet | `string` | `"10.20.0.0/16"` | no |
| `mgmt_subnet_cidr` | CIDR for the management subnet | `string` | `"10.20.0.0/24"` | no |
| `wan_subnet_cidr` | CIDR for the WAN subnet | `string` | `"10.20.1.0/24"` | no |
| `lan_subnet_cidr` | CIDR for the LAN subnet | `string` | `"10.20.2.0/24"` | no |
| `ssh_allowed_cidr` | Source CIDR for SSH access to mgmt NIC. Null = disabled | `string` | `null` | no |
| `sg_rules` | Additional NSG security rules | `list(object)` | `[]` | no |
| `app_connector_name` | Name of the App Connector | `string` | `"app-connector"` | no |
| `app_connector_vm_name` | Azure VM name | `string` | `"Cato-app-connector"` | no |
| `app_connector_description` | App Connector description | `string` | `null` | no |
| `app_connector_group` | App Connector group name in Cato | `string` | — | yes |
| `app_connector_primary_pop` | Primary PoP location name | `string` | `null` | no |
| `app_connector_secondary_pop` | Secondary PoP location name | `string` | `null` | no |
| `vm_size` | Azure VM size (must support 3 NICs) | `string` | `"Standard_D8ls_v5"` | no |
| `disk_size_gb` | OS disk size in GB | `number` | `8` | no |
| `storage_account_type` | Storage account type for OS disk | `string` | `"Standard_LRS"` | no |
| `image_publisher` | Marketplace image publisher | `string` | `"catonetworks"` | no |
| `image_offer` | Marketplace image offer | `string` | `"cato_app_connector"` | no |
| `image_sku` | Marketplace image SKU | `string` | `"public-cato-app-connector"` | no |
| `image_version` | Marketplace image version | `string` | `"23.0.19605"` | no |
| `accept_marketplace_terms` | Accept Cato marketplace terms. Set false if already accepted | `bool` | `true` | no |
| `site_location` | Override automatic site location (city_name, country_code, state_code, timezone) | `object` | All null (auto-detect) | no |
| `tags` | Tags applied to all resources | `map(any)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Resource group containing the App Connector |
| `azurerm_virtual_network_id` | ID of the virtual network |
| `wan_public_ip` | Public IP address assigned to the WAN interface |
| `wan_public_ip_id` | ID of the WAN public IP resource |
| `mgmt_nic_id` | ID of the management NIC |
| `wan_nic_id` | ID of the WAN NIC |
| `lan_nic_id` | ID of the LAN NIC |
| `mgmt_subnet_id` | ID of the management subnet |
| `wan_subnet_id` | ID of the WAN subnet |
| `lan_subnet_id` | ID of the LAN subnet |
| `nsg_id` | ID of the network security group |
| `cato_appconnector_id` | ID of the App Connector in Cato |
| `cato_appconnector_name` | Name of the App Connector in Cato |
| `cato_serial_id` | Serial ID of the App Connector |
| `site_location` | Resolved site location from Azure region mapping |
| `vm_instance_id` | Azure resource ID of the App Connector VM |
| `vm_instance_name` | Name of the VM instance |
| `vm_location` | Azure region of the VM |
| `vm_size` | Size of the VM |
| `vm_private_ip_address` | Primary private IP of the VM |
| `vm_private_ip_addresses` | All private IPs of the VM |
| `vm_public_ip_address` | Public IP of the VM (if assigned) |
| `vm_network_interface_ids` | NIC IDs attached to the VM |
| `vm_tags` | Tags assigned to the VM |
| `boot_disk_name` | Boot disk name for the VM |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.71.0 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.70 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.71.0 |
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.70 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.app_connector](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_marketplace_agreement.cato](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/marketplace_agreement) | resource |
| [azurerm_network_interface.lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_machine_extension.app_connector_custom_script](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [cato_app_connector.this](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/app_connector) | resource |
| [random_string.app_connector_random_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.app_connector_random_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_network_interface.lan-mac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wan-mac](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [cato_siteLocation.site_location](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/data-sources/siteLocation) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accept_marketplace_terms"></a> [accept\_marketplace\_terms](#input\_accept\_marketplace\_terms) | Whether Terraform should accept the Cato marketplace image terms. Set to false if the terms are already accepted on this subscription. | `bool` | `true` | no |
| <a name="input_app_connector_description"></a> [app\_connector\_description](#input\_app\_connector\_description) | AppConnector description | `string` | `null` | no |
| <a name="input_app_connector_disk_name"></a> [app\_connector\_disk\_name](#input\_app\_connector\_disk\_name) | Cato App Connector Disk name | `string` | `"Cato-app-connector-disk"` | no |
| <a name="input_app_connector_group"></a> [app\_connector\_group](#input\_app\_connector\_group) | AppConnector group name | `string` | n/a | yes |
| <a name="input_app_connector_name"></a> [app\_connector\_name](#input\_app\_connector\_name) | Name of the app-connector virtual machine | `string` | `"app-connector"` | no |
| <a name="input_app_connector_primary_pop"></a> [app\_connector\_primary\_pop](#input\_app\_connector\_primary\_pop) | Primary POP location (state) for the AppConnector | `string` | `null` | no |
| <a name="input_app_connector_secondary_pop"></a> [app\_connector\_secondary\_pop](#input\_app\_connector\_secondary\_pop) | Secondary POP location (state) for the AppConnector | `string` | `null` | no |
| <a name="input_app_connector_vm_name"></a> [app\_connector\_vm\_name](#input\_app\_connector\_vm\_name) | Azure Cato App Connector name | `string` | `"Cato-app-connector"` | no |
| <a name="input_commands"></a> [commands](#input\_commands) | n/a | `list(string)` | <pre>[<br/>  "nohup /cato/socket/run_socket_daemon.sh &"<br/>]</pre> | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Disk size in GB | `number` | `8` | no |
| <a name="input_image_offer"></a> [image\_offer](#input\_image\_offer) | Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"cato_app_connector"` | no |
| <a name="input_image_publisher"></a> [image\_publisher](#input\_image\_publisher) | Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"catonetworks"` | no |
| <a name="input_image_sku"></a> [image\_sku](#input\_image\_sku) | Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"public-cato-app-connector"` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"23.0.19605"` | no |
| <a name="input_lan_subnet_cidr"></a> [lan\_subnet\_cidr](#input\_lan\_subnet\_cidr) | CIDR for the LAN subnet (faces the protected application network). | `string` | `"10.20.2.0/24"` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created. | `string` | n/a | yes |
| <a name="input_mgmt_subnet_cidr"></a> [mgmt\_subnet\_cidr](#input\_mgmt\_subnet\_cidr) | CIDR for the management subnet. | `string` | `"10.20.0.0/24"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Name prefix applied to all created resources. | `string` | `"cato-appconn"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Azure resource group name. If null, a new resource group will be created. | `string` | `null` | no |
| <a name="input_sg_rules"></a> [sg\_rules](#input\_sg\_rules) | Security rules for the Network Security Group | <pre>list(object({<br/>    name                       = string<br/>    priority                   = number<br/>    direction                  = string<br/>    access                     = string<br/>    protocol                   = string<br/>    source_port_range          = string<br/>    destination_port_range     = string<br/>    source_address_prefix      = string<br/>    destination_address_prefix = string<br/>  }))</pre> | `[]` | no |
| <a name="input_site_location"></a> [site\_location](#input\_site\_location) | Site location which is used by the Cato App Connector to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamically. | <pre>object({<br/>    city_name    = string<br/>    country_code = string<br/>    state_code   = string<br/>    timezone     = string<br/>  })</pre> | <pre>{<br/>  "city_name": null,<br/>  "country_code": null,<br/>  "state_code": null,<br/>  "timezone": null<br/>}</pre> | no |
| <a name="input_ssh_allowed_cidr"></a> [ssh\_allowed\_cidr](#input\_ssh\_allowed\_cidr) | Optional source CIDR allowed to SSH to the mgmt NIC for troubleshooting. Null disables the inbound SSH rule. | `string` | `null` | no |
| <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type) | Storage account type | `string` | `"Standard_LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A Map of Keys and Values to Describe the infrastructure | `map(any)` | `null` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | (Required) Specifies the size of the Virtual Machine. See also Azure VM Naming Conventions. https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions | `string` | `"Standard_D8ls_v5"` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | Address space for the VNet created by this module. | `string` | `"10.20.0.0/16"` | no |
| <a name="input_wan_subnet_cidr"></a> [wan\_subnet\_cidr](#input\_wan\_subnet\_cidr) | CIDR for the WAN subnet (egress to Cato PoP). | `string` | `"10.20.1.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azurerm_virtual_network_id"></a> [azurerm\_virtual\_network\_id](#output\_azurerm\_virtual\_network\_id) | ID of the virtual network. |
| <a name="output_boot_disk_name"></a> [boot\_disk\_name](#output\_boot\_disk\_name) | Boot disk name for the VM |
| <a name="output_cato_appconnector_id"></a> [cato\_appconnector\_id](#output\_cato\_appconnector\_id) | ID of the Cato AppConnector |
| <a name="output_cato_appconnector_name"></a> [cato\_appconnector\_name](#output\_cato\_appconnector\_name) | Name of the Cato AppConnector |
| <a name="output_cato_serial_id"></a> [cato\_serial\_id](#output\_cato\_serial\_id) | Serial ID of the Cato AppConnector |
| <a name="output_lan_nic_id"></a> [lan\_nic\_id](#output\_lan\_nic\_id) | ID of the LAN NIC. |
| <a name="output_lan_subnet_id"></a> [lan\_subnet\_id](#output\_lan\_subnet\_id) | ID of the LAN subnet. |
| <a name="output_mgmt_nic_id"></a> [mgmt\_nic\_id](#output\_mgmt\_nic\_id) | ID of the management NIC. |
| <a name="output_mgmt_subnet_id"></a> [mgmt\_subnet\_id](#output\_mgmt\_subnet\_id) | ID of the management subnet. |
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | ID of the network security group. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group containing the App Connector. |
| <a name="output_site_location"></a> [site\_location](#output\_site\_location) | The resolved site location from Azure region mapping |
| <a name="output_vm_instance_id"></a> [vm\_instance\_id](#output\_vm\_instance\_id) | ID of the VM instance |
| <a name="output_vm_instance_name"></a> [vm\_instance\_name](#output\_vm\_instance\_name) | Name of the VM instance |
| <a name="output_vm_location"></a> [vm\_location](#output\_vm\_location) | Azure region of the VM |
| <a name="output_vm_network_interface_ids"></a> [vm\_network\_interface\_ids](#output\_vm\_network\_interface\_ids) | Network interface IDs attached to the VM |
| <a name="output_vm_private_ip_address"></a> [vm\_private\_ip\_address](#output\_vm\_private\_ip\_address) | Primary private IP address of the VM |
| <a name="output_vm_private_ip_addresses"></a> [vm\_private\_ip\_addresses](#output\_vm\_private\_ip\_addresses) | Private IP addresses of the VM |
| <a name="output_vm_public_ip_address"></a> [vm\_public\_ip\_address](#output\_vm\_public\_ip\_address) | Primary public IP address of the VM if assigned |
| <a name="output_vm_size"></a> [vm\_size](#output\_vm\_size) | Size of the VM |
| <a name="output_vm_tags"></a> [vm\_tags](#output\_vm\_tags) | Tags assigned to the VM |
| <a name="output_wan_nic_id"></a> [wan\_nic\_id](#output\_wan\_nic\_id) | ID of the WAN NIC. |
| <a name="output_wan_public_ip"></a> [wan\_public\_ip](#output\_wan\_public\_ip) | Public IP address assigned to the WAN interface. |
| <a name="output_wan_public_ip_id"></a> [wan\_public\_ip\_id](#output\_wan\_public\_ip\_id) | ID of the WAN public IP resource. |
| <a name="output_wan_subnet_id"></a> [wan\_subnet\_id](#output\_wan\_subnet\_id) | ID of the WAN subnet. |
<!-- END_TF_DOCS -->