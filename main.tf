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
  name     = "hashicraft2"
  location = "West Europe"
}

resource "azurerm_container_group" "minecraft" {
  name                = "minecraft-server"
  location            = azurerm_resource_group.minecraft.location
  resource_group_name = azurerm_resource_group.minecraft.name
  ip_address_type     = "public"
  dns_name_label      = "tfdemohs"
  os_type             = "Linux"

  container {
    name = "server"
    image = "hashicraft/minecraft:v1.12.2"
    cpu = "0.5"
    memory = "1"

    # Main minecraft port
    ports {
      port     = 25565
      protocol = "TCP"
    }

    # RCon server port 
    ports {
      port     = 27015
      protocol = "TCP"
    }

     environment_variables = {
      MINECRAFT_MOTD="HashiCraft",
      MINECRAFT_WHITELIST_ENABLED=true,
      MINECRAFT_RCON_ENABLED=true
      MINECRAFT_RCON_PASSWORD=random_password.password.result
     }
  }

  }

output "fqdn" {
  value = azurerm_container_group.minecraft.fqdn
}

output "rcon_password" {
  value = random_password.password.result
}