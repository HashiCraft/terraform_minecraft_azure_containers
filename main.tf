provider "azurerm" {
  version = "=2.5.0"
  features {}
}

terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "HashiCraft"

    workspaces {
      prefix = "terraform_minecraft_azure_containers_"
    }
  }
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

variable "environment" {
  default = "dev"
}

resource "azurerm_resource_group" "minecraft" {
  name     = "hasicrafttest${var.environment == "master" ? "" : var.environment}"
  location = "West Europe"
}

resource "azurerm_storage_account" "minecraft" {
  name                     = "hashicrafttf${var.environment == "master" ? "" : var.environment}"
  resource_group_name      = azurerm_resource_group.minecraft.name
  location                 = azurerm_resource_group.minecraft.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "production"
  }
}

resource "azurerm_storage_share" "minecraft_world" {
  name = "world"
  storage_account_name = azurerm_storage_account.minecraft.name
  quota = 50
}

resource "azurerm_storage_share" "minecraft_config" {
  name                 = "config"
  storage_account_name = azurerm_storage_account.minecraft.name
  quota                = 1
}

resource "azurerm_container_group" "minecraft" {
  name                = "minecraft"
  location            = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  ip_address_type     = "public"
  dns_name_label      = "hashicrafttf${var.environment == "master" ? "" : var.environment}"
  os_type             = "Linux"

  container {
    name   = "studio"
    image = "hashicraft/minecraft:v1.12.2"
    cpu = "1"
    memory = "1"

    # Main minecraft port
    ports {
      port     = 25565
      protocol = "TCP"
    } 

    volume {
      name = "world"
      mount_path = "/minecraft/world"
      storage_account_name = azurerm_storage_account.minecraft.name
      storage_account_key = azurerm_storage_account.minecraft.primary_access_key
      share_name = azurerm_storage_share.minecraft_world.name  
    }

    volume {
      name = "config"
      mount_path = "/minecraft/config"
      storage_account_name = azurerm_storage_account.minecraft.name
      storage_account_key = azurerm_storage_account.minecraft.primary_access_key
      share_name = azurerm_storage_share.minecraft_config.name  
    }

    environment_variables = {
      JAVA_MEMORY="1G",
      MINECRAFT_MOTD="HashiCraft",
      RESOURCE_PACK="https://github.com/HashiCraft/terraform_minecraft_azure_containers/releases/download/files/KawaiiWorld1.12.zip",
      WORLD_BACKUP="https://github.com/HashiCraft/terraform_minecraft_azure_containers/releases/download/files/example_world.tar.gz",
      WHITELIST_ENABLED=true,
      RCON_ENABLED=true,
      RCON_PASSWORD=random_password.password.result
    }
  }
}

output "fqdn" {
  value = azurerm_container_group.minecraft.fqdn
}

output "rcon_password" {
  value = random_password.password.result
}
