# Cato Networks Azure appConnector Terraform Module

The Cato appConnector module deploys an appConnector instance to connect to the Cato Cloud.

- *Note: This feature is currently in Early Availability (EA) and has been rolled out to a limited set of customer accounts for testing and validation purposes.*

# Pre-reqs
- Install the [Azure Cloud CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Run the following to configure the Azure CLI
`$ az login`

# Azure Network and Resource Dependencies

<details>
<summary>Create new Azure VPC and network resources</summary>

The following exmaple shows how to create the required resources as new.

```hcl
resource "azurerm_virtual_network" "appconn_vnet" {
  name                = "appconn_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.appconn_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "lan" {
  name                 = "lan"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.appconn_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "wan" {
  name                 = "wan"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.appconn_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_network_interface" "mgmt" {
  name                = "mgmt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.mgmt_private_ip
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.mgmt.id
  }
}

resource "azurerm_network_interface" "lan" {
  name                = "lan"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "lan"
    subnet_id                     = azurerm_subnet.lan.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_private_ip
    private_ip_address_version    = "IPv4"
  }
}

resource "azurerm_network_interface" "wan" {
  name                = "wan"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "wan"
    subnet_id                     = azurerm_subnet.wan.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.wan_private_ip
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.wan.id
  }
}


resource "azurerm_public_ip" "mgmt" {
  name                = "mgmt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "wan" {
  name                = "wan"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "1.2.3.4/32" # Replace with your public IP
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.mgmt.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Note: uncomment this resource if Azure complains about marketplace agreement 
# resource "azurerm_marketplace_agreement" "cato-agreement" {
#   publisher = "catonetworks"
#   offer     = "catoappconnector"
#   plan      = "appconnector"
# } 
```
</details>

## Usage

```hcl
module "app_conn" {
  source                  = "catonetworks/appconnector-azure/cato"
  location                = azurerm_resource_group.this.location
  vm_size                 = "Standard_D8ls_v5"
  disk_size_gb            = 30
  resource_group_name     = azurerm_resource_group.this.name
  mgmt_nic_id             = azurerm_network_interface.mgmt.id
  wan_nic_id              = azurerm_network_interface.wan.id
  lan_nic_id              = azurerm_network_interface.lan.id
  app_connector_disk_name = "app_connector_disk"
  app_connector_vm_name   = "app_connector_vm"

  image_publisher = "catonetworks"
  image_offer     = "catoappconnector"
  image_sku       = "appconnector"
  image_version   = "latest"

  tags = {
    owner = "a.u.thor@example.com"
  }

  app_connector_name          = "appcon-site1-azure"
  app_connector_description   = "make site1-azure app accessible"
  app_connector_group         = "site1-azure"
  app_connector_address       = "123 Main St"
  app_connector_city          = "San Francisco"
  app_connector_country_code  = "US"
  app_connector_state_code    = "US-CA"
  app_connector_timezone      = "America/Los_Angeles"
  app_connector_primary_pop   = "New York"
  app_connector_secondary_pop = "Chicago"

  depends_on = [
    azurerm_network_interface.mgmt,
    azurerm_network_interface.lan,
    azurerm_network_interface.wan,
  ]
}
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.71.0 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.70 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.71.0 |
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.70 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_linux_virtual_machine.app_connector](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_virtual_machine_extension.app_connector_custom_script](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [cato_app_connector.this](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/app_connector) | resource |
| [random_string.app_connector_random_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.app_connector_random_username](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_network_interface.lan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |
| [azurerm_network_interface.wan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_interface) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_app_connector_address"></a> [app\_connector\_address](#input\_app\_connector\_address) | AppConnector address (street) | `string` | `null` | no |
| <a name="input_app_connector_city"></a> [app\_connector\_city](#input\_app\_connector\_city) | AppConnector city name (in the given country) | `string` | n/a | yes |
| <a name="input_app_connector_country_code"></a> [app\_connector\_country\_code](#input\_app\_connector\_country\_code) | AppConnector country code | `string` | n/a | yes |
| <a name="input_app_connector_description"></a> [app\_connector\_description](#input\_app\_connector\_description) | AppConnector description | `string` | `null` | no |
| <a name="input_app_connector_disk_name"></a> [app\_connector\_disk\_name](#input\_app\_connector\_disk\_name) | Cato App Connector Disk name | `string` | `"Cato-app-connector-disk"` | no |
| <a name="input_app_connector_group"></a> [app\_connector\_group](#input\_app\_connector\_group) | AppConnector group name | `string` | n/a | yes |
| <a name="input_app_connector_name"></a> [app\_connector\_name](#input\_app\_connector\_name) | Name of the app-connector virtual machine | `string` | `"app-connector"` | no |
| <a name="input_app_connector_primary_pop"></a> [app\_connector\_primary\_pop](#input\_app\_connector\_primary\_pop) | Primary POP location (state) for the AppConnector | `string` | `null` | no |
| <a name="input_app_connector_secondary_pop"></a> [app\_connector\_secondary\_pop](#input\_app\_connector\_secondary\_pop) | Secondary POP location (state) for the AppConnector | `string` | `null` | no |
| <a name="input_app_connector_state_code"></a> [app\_connector\_state\_code](#input\_app\_connector\_state\_code) | AppConnector state code (required for the USA) | `string` | n/a | yes |
| <a name="input_app_connector_timezone"></a> [app\_connector\_timezone](#input\_app\_connector\_timezone) | AppConnector timezone | `string` | n/a | yes |
| <a name="input_app_connector_vm_name"></a> [app\_connector\_vm\_name](#input\_app\_connector\_vm\_name) | Azure Cato App Connector name | `string` | `"Cato-app-connector"` | no |
| <a name="input_commands"></a> [commands](#input\_commands) | n/a | `list(string)` | <pre>[<br/>  "nohup /cato/socket/run_socket_daemon.sh &"<br/>]</pre> | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Disk size in GB | `number` | `8` | no |
| <a name="input_image_offer"></a> [image\_offer](#input\_image\_offer) | Specifies the offer of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"cato_app_connector"` | no |
| <a name="input_image_publisher"></a> [image\_publisher](#input\_image\_publisher) | Specifies the publisher of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"catonetworks"` | no |
| <a name="input_image_sku"></a> [image\_sku](#input\_image\_sku) | Specifies the SKU of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"public-cato-app-connector"` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | Specifies the version of the image used to create the virtual machines. Changing this forces a new resource to be created. | `string` | `"23.0.19605"` | no |
| <a name="input_lan_nic_name"></a> [lan\_nic\_name](#input\_lan\_nic\_name) | Name of the primary LAN network interface. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | (Required) The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created. | `string` | n/a | yes |
| <a name="input_mgmt_nic_name"></a> [mgmt\_nic\_name](#input\_mgmt\_nic\_name) | Name of the primary management network interface. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) The Name which should be used for this Resource Group. Changing this forces a new Resource Group to be created. | `string` | n/a | yes |
| <a name="input_storage_account_type"></a> [storage\_account\_type](#input\_storage\_account\_type) | Storage account type | `string` | `"Standard_LRS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A Map of Keys and Values to Describe the infrastructure | `map(any)` | `null` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | (Required) Specifies the size of the Virtual Machine. See also Azure VM Naming Conventions. https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions | `string` | `"Standard_D8ls_v5"` | no |
| <a name="input_wan_nic_name"></a> [wan\_nic\_name](#input\_wan\_nic\_name) | Name of the primary WAN network interface. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_boot_disk_name"></a> [boot\_disk\_name](#output\_boot\_disk\_name) | Boot disk name for the VM |
| <a name="output_cato_appconnector_id"></a> [cato\_appconnector\_id](#output\_cato\_appconnector\_id) | ID of the Cato AppConnector |
| <a name="output_cato_appconnector_name"></a> [cato\_appconnector\_name](#output\_cato\_appconnector\_name) | Name of the Cato AppConnector |
| <a name="output_cato_serial_id"></a> [cato\_serial\_id](#output\_cato\_serial\_id) | Serial ID of the Cato AppConnector |
| <a name="output_vm_instance_id"></a> [vm\_instance\_id](#output\_vm\_instance\_id) | ID of the VM instance |
| <a name="output_vm_instance_name"></a> [vm\_instance\_name](#output\_vm\_instance\_name) | Name of the VM instance |
| <a name="output_vm_location"></a> [vm\_location](#output\_vm\_location) | Azure region of the VM |
| <a name="output_vm_network_interface_ids"></a> [vm\_network\_interface\_ids](#output\_vm\_network\_interface\_ids) | Network interface IDs attached to the VM |
| <a name="output_vm_private_ip_address"></a> [vm\_private\_ip\_address](#output\_vm\_private\_ip\_address) | Primary private IP address of the VM |
| <a name="output_vm_private_ip_addresses"></a> [vm\_private\_ip\_addresses](#output\_vm\_private\_ip\_addresses) | Private IP addresses of the VM |
| <a name="output_vm_public_ip_address"></a> [vm\_public\_ip\_address](#output\_vm\_public\_ip\_address) | Primary public IP address of the VM if assigned |
| <a name="output_vm_size"></a> [vm\_size](#output\_vm\_size) | Size of the VM |
| <a name="output_vm_tags"></a> [vm\_tags](#output\_vm\_tags) | Tags assigned to the VM |
<!-- END_TF_DOCS -->
