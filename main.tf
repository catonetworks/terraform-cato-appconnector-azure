locals {
  clean_ac_name = regex("^[a-z][-a-z0-9]{0,61}[a-z0-9]?$", replace(lower(var.app_connector_name), "_", "-"))
}


# AppConnector resource in the Cato Management Application
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


