############## AzureRM
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "primary" {}

############# NSG | Client data
data "http" "clientip" {
  url = "https://ipv4.icanhazip.com/"
}

############# NSG | Client data

############ Admin User VM
data "azuread_user" "tfaz-dc01-admin" {
  user_principal_name = azuread_user.tfaz-dc01-admin.display_name
}