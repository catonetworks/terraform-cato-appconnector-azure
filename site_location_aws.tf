locals {
  # Check if user provided site_location (any field is non-null)
  use_user_location = (
    var.site_location.city_name != null ||
    var.site_location.country_code != null ||
    var.site_location.state_code != null ||
    var.site_location.timezone != null
  )

  locationstr = lower(replace(var.location, " ", ""))

  # Manual mapping of Azure regions to their cities and countries
  # Since Azure doesn't provide city/country in the API, we create our own mapping
  # Note: Only US, AU, IN, BR state codes work - all others must be null
  region_to_site_location = {
    # North America - United States
    "eastus"         = { city_name = "Ashburn", country_code = "US", state_code = "US-VA", timezone = "America/New_York" }
    "eastus2"        = { city_name = "Ashburn", country_code = "US", state_code = "US-VA", timezone = "America/New_York" }
    "centralus"      = { city_name = "Des Moines", country_code = "US", state_code = "US-IA", timezone = "America/Chicago" }
    "northcentralus" = { city_name = "Chicago", country_code = "US", state_code = "US-IL", timezone = "America/Chicago" }
    "southcentralus" = { city_name = "San Antonio", country_code = "US", state_code = "US-TX", timezone = "America/Chicago" }
    "westcentralus"  = { city_name = "Cheyenne", country_code = "US", state_code = "US-WY", timezone = "America/Denver" }
    "westus"         = { city_name = "San Francisco", country_code = "US", state_code = "US-CA", timezone = "America/Los_Angeles" }
    "westus2"        = { city_name = "Seattle", country_code = "US", state_code = "US-WA", timezone = "America/Los_Angeles" }
    "westus3"        = { city_name = "Phoenix", country_code = "US", state_code = "US-AZ", timezone = "America/Phoenix" }

    # North America - Canada
    "canadacentral" = { city_name = "Toronto", country_code = "CA", state_code = null, timezone = "America/Toronto" }
    "canadaeast"    = { city_name = "Montréal", country_code = "CA", state_code = null, timezone = "America/Toronto" }

    # Europe
    "northeurope"        = { city_name = "Dublin", country_code = "IE", state_code = null, timezone = "Europe/Dublin" }
    "westeurope"         = { city_name = "Brussels", country_code = "BE", state_code = null, timezone = "Europe/Brussels" }
    "francecentral"      = { city_name = "Paris", country_code = "FR", state_code = null, timezone = "Europe/Paris" }
    "francesouth"        = { city_name = "Marseille", country_code = "FR", state_code = null, timezone = "Europe/Paris" }
    "germanywestcentral" = { city_name = "Frankfurt am Main", country_code = "DE", state_code = null, timezone = "Europe/Berlin" }
    "germanynorth"       = { city_name = "Berlin", country_code = "DE", state_code = null, timezone = "Europe/Berlin" }
    "norwayeast"         = { city_name = "Oslo", country_code = "NO", state_code = null, timezone = "Europe/Oslo" }
    "norwaywest"         = { city_name = "Oslo", country_code = "NO", state_code = null, timezone = "Europe/Oslo" }
    "swedencentral"      = { city_name = "Stockholm", country_code = "SE", state_code = null, timezone = "Europe/Stockholm" }
    "switzerlandnorth"   = { city_name = "Zürich", country_code = "CH", state_code = null, timezone = "Europe/Zurich" }
    "switzerlandwest"    = { city_name = "Genève", country_code = "CH", state_code = null, timezone = "Europe/Zurich" }
    "uksouth"            = { city_name = "London", country_code = "GB", state_code = null, timezone = "Europe/London" }
    "ukwest"             = { city_name = "Cardiff", country_code = "GB", state_code = null, timezone = "Europe/London" }
    "polandcentral"      = { city_name = "Warsaw", country_code = "PL", state_code = null, timezone = "Europe/Warsaw" }

    # Asia Pacific
    "eastasia"        = { city_name = "Hong Kong", country_code = "HK", state_code = null, timezone = "Asia/Hong_Kong" }
    "southeastasia"   = { city_name = "Singapore", country_code = "SG", state_code = null, timezone = "Asia/Singapore" }
    "centralindia"    = { city_name = "Pune", country_code = "IN", state_code = "IN-MH", timezone = "Asia/Kolkata" }
    "southindia"      = { city_name = "Chennai", country_code = "IN", state_code = "IN-TN", timezone = "Asia/Kolkata" }
    "westindia"       = { city_name = "Mumbai", country_code = "IN", state_code = "IN-MH", timezone = "Asia/Kolkata" }
    "jioindiacentral" = { city_name = "Jamnagar", country_code = "IN", state_code = "IN-GJ", timezone = "Asia/Kolkata" }
    "jioindiawest"    = { city_name = "Jamnagar", country_code = "IN", state_code = "IN-GJ", timezone = "Asia/Kolkata" }
    "japaneast"       = { city_name = "Tokyo", country_code = "JP", state_code = null, timezone = "Asia/Tokyo" }
    "japanwest"       = { city_name = "Osaka", country_code = "JP", state_code = null, timezone = "Asia/Tokyo" }
    "koreacentral"    = { city_name = "Seoul", country_code = "KR", state_code = null, timezone = "Asia/Seoul" }
    "koreasouth"      = { city_name = "Busan", country_code = "KR", state_code = null, timezone = "Asia/Seoul" }

    # Asia Pacific - Australia
    "australiaeast"      = { city_name = "Sydney", country_code = "AU", state_code = "AU-NSW", timezone = "Australia/Sydney" }
    "australiacentral"   = { city_name = "Canberra", country_code = "AU", state_code = "AU-ACT", timezone = "Australia/Sydney" }
    "australiacentral2"  = { city_name = "Canberra", country_code = "AU", state_code = "AU-ACT", timezone = "Australia/Sydney" }
    "australiasoutheast" = { city_name = "Melbourne", country_code = "AU", state_code = "AU-VIC", timezone = "Australia/Melbourne" }

    # Middle East
    "uaenorth"     = { city_name = "Dubai", country_code = "AE", state_code = null, timezone = "Asia/Dubai" }
    "uaecentral"   = { city_name = "Abu Dhabi", country_code = "AE", state_code = null, timezone = "Asia/Dubai" }
    "qatarcentral" = { city_name = "Doha", country_code = "QA", state_code = null, timezone = "Asia/Qatar" }

    # Africa
    "southafricanorth" = { city_name = "Johannesburg", country_code = "ZA", state_code = null, timezone = "Africa/Johannesburg" }
    "southafricawest"  = { city_name = "Cape Town", country_code = "ZA", state_code = null, timezone = "Africa/Johannesburg" }

    # South America
    "brazilsouth" = { city_name = "São Paulo", country_code = "BR", state_code = "BR-SP", timezone = "UTC-3" }
  }

  # Use user-provided location if any field is set, otherwise use hardcoded mapping
  cur_site_location = local.use_user_location ? var.site_location : local.region_to_site_location[local.locationstr]
}

output "site_location" {
  description = "The resolved site location from Azure region mapping"
  value       = local.cur_site_location
}
