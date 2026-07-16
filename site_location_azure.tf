
data "cato_siteLocation" "site_location" {
  count = local.all_location_fields_null ? 1 : 0
  filters = concat([
    {
      field     = "city"
      operation = "exact"
      search    = local.region_to_location[local.locationstr].city
    },
    {
      field     = "country_name"
      operation = "exact"
      search    = local.region_to_location[local.locationstr].country
    }
    ],
    local.region_to_location[local.locationstr].state != null ? [
      {
        field     = "state_name"
        operation = "exact"
        search    = local.region_to_location[local.locationstr].state
      }
  ] : [])
}

locals {
  ## Check for all site_location inputs to be null
  all_location_fields_null = (
    var.site_location.city_name == null &&
    var.site_location.country_code == null &&
    var.site_location.state_code == null &&
    var.site_location.timezone == null
  ) ? true : false

  ## If all site_location fields are null, use the data source to fetch the
  ## site_location from azure provider location, else use var.site_location
  cur_site_location = local.all_location_fields_null ? {
    city_name    = data.cato_siteLocation.site_location[0].locations[0].city
    country_code = data.cato_siteLocation.site_location[0].locations[0].country_code
    state_code   = data.cato_siteLocation.site_location[0].locations[0].state_code
    timezone     = data.cato_siteLocation.site_location[0].locations[0].timezone[0]
  } : var.site_location

  locationstr = lower(replace(var.location, " ", ""))

  # Manual mapping of Azure regions to their cities and countries
  # Since Azure doesn't provide city/country in the API, we create our own mapping
  region_to_location = {
    # North America - United States
    "eastus"         = { city = "Ashburn", state = "Virginia", country = "United States" }
    "eastus2"        = { city = "Ashburn", state = "Virginia", country = "United States" }
    "centralus"      = { city = "Des Moines", state = "Iowa", country = "United States" }
    "northcentralus" = { city = "Chicago", state = "Illinois", country = "United States" }
    "southcentralus" = { city = "San Antonio", state = "Texas", country = "United States" }
    "westcentralus"  = { city = "Cheyenne", state = "Wyoming", country = "United States" }
    "westus"         = { city = "San Francisco", state = "California", country = "United States" }
    "westus2"        = { city = "Seattle", state = "Washington", country = "United States" }
    "westus3"        = { city = "Phoenix", state = "Arizona", country = "United States" }

    # North America - Canada
    "canadacentral" = { city = "Toronto", state = null, country = "Canada" }
    "canadaeast"    = { city = "Montréal", state = null, country = "Canada" }

    # Europe
    "northeurope"        = { city = "Dublin", state = null, country = "Ireland" }
    "westeurope"         = { city = "Amsterdam", state = null, country = "Netherlands" }
    "francecentral"      = { city = "Paris", state = null, country = "France" }
    "francesouth"        = { city = "Marseille", state = null, country = "France" }
    "germanywestcentral" = { city = "Frankfurt (Oder)", state = null, country = "Germany" }
    "germanynorth"       = { city = "Berlin", state = null, country = "Germany" }
    "norwayeast"         = { city = "Oslo", state = null, country = "Norway" }
    "norwaywest"         = { city = "Stavanger", state = null, country = "Norway" }
    "swedencentral"      = { city = "Gävle", state = null, country = "Sweden" }
    "switzerlandnorth"   = { city = "Zürich", state = null, country = "Switzerland" }
    "switzerlandwest"    = { city = "Genève", state = null, country = "Switzerland" }
    "uksouth"            = { city = "London", state = null, country = "United Kingdom" }
    "ukwest"             = { city = "Cardiff", state = null, country = "United Kingdom" }

    # Asia Pacific
    "eastasia"        = { city = "Hong Kong", state = null, country = "Hong Kong" }
    "southeastasia"   = { city = "Singapore", state = null, country = "Singapore" }
    "centralindia"    = { city = "Pune", state = "Maharashtra", country = "India" }
    "southindia"      = { city = "Chennai", state = "Tamil Nadu", country = "India" }
    "westindia"       = { city = "Mumbai", state = "Maharashtra", country = "India" }
    "jioindiacentral" = { city = "Jamnagar", state = "Gujarat", country = "India" }
    "jioindiawest"    = { city = "Jamnagar", state = "Gujarat", country = "India" }
    "japaneast"       = { city = "Tokyo", state = null, country = "Japan" }
    "japanwest"       = { city = "Osaka", state = null, country = "Japan" }
    "koreacentral"    = { city = "Seoul", state = null, country = "South Korea" }
    "koreasouth"      = { city = "Busan", state = null, country = "South Korea" }

    # Asia Pacific - Australia
    "australiaeast"      = { city = "Sydney", state = "New South Wales", country = "Australia" }
    "australiacentral"   = { city = "Canberra", state = "Australian Capital Territory", country = "Australia" }
    "australiacentral2"  = { city = "Canberra", state = "Australian Capital Territory", country = "Australia" }
    "australiasoutheast" = { city = "Melbourne", state = "Victoria", country = "Australia" }

    # Middle East
    "uaenorth"     = { city = "Dubai", state = null, country = "United Arab Emirates" }
    "uaecentral"   = { city = "Abu Dhabi", state = null, country = "United Arab Emirates" }
    "qatarcentral" = { city = "Doha", state = null, country = "Qatar" }

    # Africa
    "southafricanorth" = { city = "Johannesburg", state = null, country = "South Africa" }
    "southafricawest"  = { city = "Cape Town", state = null, country = "South Africa" }

    # South America
    "brazilsouth" = { city = "São Paulo", state = "São Paulo", country = "Brazil" }
  }
}

output "site_location" {
  description = "The resolved site location from Azure region mapping"
  value       = data.cato_siteLocation.site_location
}
