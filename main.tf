provider "azurerm" {
  version = "=2.5.0"
  features {}
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "minecraft" {
  name     = "hasicrafttest"
  location = "West Europe"
}

resource "azurerm_container_group" "minecraft" {
  name                = "minecraft"
  location            = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  ip_address_type     = "public"
  dns_name_label      = "hashicrafttf"
  os_type             = "Linux"

  container {
    name   = "studio"
    image = "hashicraft/minecraft:v1.12.2"
    cpu = "0.5"
    memory = "1"

    # Main minecraft port
    ports {
      port     = 25565
      protocol = "TCP"
    } 

    environment_variables = {
      JAVA_MEMORY="1G",
      MINECRAFT_MOTD="HashiCraft",
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