# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "TF-ray-resume"
  location = "eastus"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "tfrayresume"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_account" "func_storage_account" {
  name                     = "tfrayresumefunc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = "rcalazan.com"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "resumecdnprofile"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "tfrayresume-cdn"
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  origin {
    name      = "tfrayresumecdn"
    host_name = "tfrayresume.z13.web.core.windows.net"
  }
  origin_host_header = "tfrayresume.z13.web.core.windows.net"
}

resource "azurerm_dns_cname_record" "cdn_cname" {
  name                = "www"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.cdn_endpoint.id
}

resource "azurerm_cdn_endpoint_custom_domain" "custom_domain" {
  name            = "rcalazan"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn_endpoint.id
  host_name       = "${azurerm_dns_cname_record.cdn_cname.name}.${azurerm_dns_zone.dns_zone.name}"
  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
  }
}

resource "azurerm_cosmosdb_account" "cosmosdb-resume" {
  location            = azurerm_resource_group.rg.location
  name                = "tf-ray-resume-cosmosdb"
  offer_type          = "Standard"
  resource_group_name = azurerm_resource_group.rg.name

  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    failover_priority = 0
    location          = azurerm_resource_group.rg.location
  }
}

resource "azurerm_cosmosdb_sql_database" "resume-db" {
  name                = "tf-resume-db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb-resume.name
}

resource "azurerm_cosmosdb_sql_container" "resume-container" {
  name                = "db-container"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb-resume.name
  database_name       = azurerm_cosmosdb_sql_database.resume-db.name
  partition_key_path  = "/definition/id"
}
resource "azurerm_service_plan" "service_plan" {
  name                = "tf-rayresume-service-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}
resource "azurerm_linux_function_app" "function_app" {
  name                 = "tf-ray-resume-function"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  service_plan_id      = azurerm_service_plan.service_plan.id
  storage_account_name = azurerm_storage_account.func_storage_account.name
  site_config {
    cors {
      allowed_origins = [
        "https://portal.azure.com",
        "https://www.rcalazan.com",
        azurerm_storage_account.storage_account.primary_web_endpoint
      ]
    }
  }
}

output "name_servers" {
  value = azurerm_dns_zone.dns_zone.name_servers
}

output "website_endpoint" {
  value = azurerm_storage_account.storage_account.primary_web_endpoint
}
