# Changelog

## 0.0.2 (2026-07-16)

### Features
- Embedded all Azure networking resources into the module (VNet, subnets, NSG, NICs, public IP, marketplace agreement)
- Conditional resource group creation — use existing when `resource_group_name` is provided, create new when null
- Added `prefix` variable for resource naming
- Added configurable NSG rules via `sg_rules` and optional SSH access via `ssh_allowed_cidr`
- Updated site location to use `data "cato_siteLocation"` for dynamic resolution from Azure region
- Fixed marketplace image defaults to `catoappconnector` / `appconnector`
- Updated README with usage examples

## 0.0.1 (2026-05-06)

### Changed
- Updated AzureRM to 4.71.0
