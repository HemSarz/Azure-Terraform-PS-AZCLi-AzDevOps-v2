############ ResourceGroup ############

resource "azurerm_resource_group" "tfaz-rg" {
  name     = var.tfaz-rg_label
  location = var.location
}

############ Storage Account ############

resource "azurerm_storage_account" "tfaz-stg" {
  name                     = var.tfaz-stg
  resource_group_name      = azurerm_resource_group.tfaz-rg.name
  location                 = var.location
  depends_on               = [azurerm_resource_group.tfaz-rg]
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#### Storage Container #####

resource "azurerm_storage_container" "tfaz-cont" {
  name                  = var.tfaz-stg-cont
  storage_account_name  = azurerm_storage_account.tfaz-stg.name
  depends_on            = [azurerm_storage_account.tfaz-stg]
  container_access_type = "private"
}

############ KeyVault ############

resource "random_id" "tfaz-key-vault" {
  byte_length = 4
  prefix      = var.kv-name-rndm
}

resource "azurerm_key_vault" "tfaz-kv" {
  name                = random_id.tfaz-key-vault.hex
  location            = var.location
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  depends_on          = [azurerm_resource_group.tfaz-rg]

  sku_name = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  access_policy {
    object_id = data.azurerm_client_config.current.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id

    key_permissions     = ["Get", "List", "Backup"]
    secret_permissions  = ["Get", "List", "Set", "Delete", "Purge"]
    storage_permissions = ["Get", "List", "Set"]
  }

}

############ KV Secrets ############

resource "azurerm_key_vault_secret" "kv-sc-tfaz-vmadmin" {
  name         = var.kv-sc-dc01-admin-label
  value        = var.kv-sc-dc01-adminuser
  key_vault_id = azurerm_key_vault.tfaz-kv.id
  depends_on = [
    azurerm_key_vault.tfaz-kv
  ]
}

resource "azurerm_key_vault_secret" "kv-sc-tfaz-vm-pass" {
  name         = var.kv-sc-dc01-admin-pass-label
  value        = random_password.vm-admin-pass.result
  key_vault_id = azurerm_key_vault.tfaz-kv.id
  depends_on = [
    azurerm_key_vault.tfaz-kv
  ]
}

############ Admin User ############

resource "random_password" "vm-admin-pass" {
  length           = 12
  special          = true
  override_special = "%&*()-_=+[]{}<>:?"
  upper            = true
  lower            = true
}

resource "azuread_user" "tfaz-dc01-admin" {
  user_principal_name = var.tfaz-dc01-admin_upn
  display_name        = azurerm_key_vault_secret.kv-sc-tfaz-vmadmin.value
  password            = random_password.vm-admin-pass.result
}

############ Virtual Network ############

resource "azurerm_virtual_network" "tfaz-vnet1" {
  name                = var.tfaz-vnet1-label
  location            = azurerm_resource_group.tfaz-rg.location
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  address_space       = [var.tfaz-vnet1-subnet1-addr-space]
}

resource "azurerm_virtual_network" "tfaz-vnet2" {
  name                = var.tfaz-vnet2-label
  location            = var.location
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  address_space       = [var.tfaz-vnet2-subnet1-addr-space]
}

############ Virtual Network: Subnet1 ############

resource "azurerm_subnet" "tfaz-vnet1-subnet1" {
  name                 = var.tfaz-vnet1-label
  address_prefixes     = [var.tfaz-infra-vnet1-subnet1-range]
  resource_group_name  = azurerm_resource_group.tfaz-rg.name
  virtual_network_name = azurerm_virtual_network.tfaz-vnet1.name
}

############ Virtual Network Subnet2 ############

resource "azurerm_subnet" "tfaz-vnet2-subn1" {
  name                 = var.tfaz-vnet2-subnet1-label
  resource_group_name  = azurerm_resource_group.tfaz-rg.name
  virtual_network_name = azurerm_virtual_network.tfaz-vnet2.name
  address_prefixes     = [var.tfaz-vnet2-subnet1-range]
}

############ VN Peering | SUBNET1 ---> SUBNET2 ############

############ VN Peering | SUBNET2 ---> SUBNET1 ############

############ Network Interface ############

resource "azurerm_network_interface" "tfaz-netint-dc01" {
  name                = var.dc01-netwint
  location            = azurerm_resource_group.tfaz-rg.location
  resource_group_name = azurerm_resource_group.tfaz-rg.name

  ip_configuration {
    name                          = var.tfaz-ipconfig
    subnet_id                     = azurerm_subnet.tfaz-vnet1-subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.tfaz-netwint-priv-ip-dc01
    public_ip_address_id          = azurerm_public_ip.tfaz-dc01-pip.id
  }
}

############ Virtual Machine ############

resource "azurerm_windows_virtual_machine" "tfaz-vm-dco1" {
  name                = var.dc01-label
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  location            = azurerm_resource_group.tfaz-rg.location
  size                = var.vm_size
  admin_username      = azurerm_key_vault_secret.kv-sc-tfaz-vmadmin.value
  admin_password      = random_password.vm-admin-pass.result
  network_interface_ids = [
    azurerm_network_interface.tfaz-netint-dc01.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.storageimage_publisher
    offer     = var.storageimage_offer
    sku       = var.storageimage_sku
    version   = var.storageimage_version
  }
}

############ Public IP ############

resource "azurerm_public_ip" "tfaz-dc01-pip" {
  name                = var.PIP-dc01
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  location            = azurerm_resource_group.tfaz-rg.location
  allocation_method   = "Static"

}

############ Network Security Group | NSG Association ############

resource "azurerm_network_security_group" "tfaz-nsg-client" {
  name                = var.NSG-AllowClient
  resource_group_name = azurerm_resource_group.tfaz-rg.name
  location            = var.location

  security_rule {
    name                       = var.sec-rule-allow-rdp-client
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "82.164.170.66"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.env-tfaz-dev
  }
}

resource "azurerm_network_interface_security_group_association" "tfaz-nsg-client-assoc" {
  network_interface_id      = azurerm_network_interface.tfaz-netint-dc01.id
  network_security_group_id = azurerm_network_security_group.tfaz-nsg-client.id
}