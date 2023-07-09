###############################################################
# Resource Group | Environment | Location
###############################################################

variable "tfaz-rg_label" {
  type        = string
  default     = "tfaz-infra-rg"
  description = "description"
}

variable "env-tfaz-dev" {
  type        = string
  default     = "tfaz-infra-dev"
  description = "description"
}

variable "location" {
  type        = string
  default     = "norwayeast"
  description = "description"
}


###############################################################
# Storage account | Container
###############################################################

variable "tfaz-stg" {
  type        = string
  default     = "tfazstg"
  description = "description"
}

variable "tfaz-stg-cont" {
  type        = string
  default     = "tfaz-infra-cont"
  description = "description"
}

###############################################################
# Key Vault | Secrets
###############################################################

variable "kv-name-rndm" {
  type    = string
  default = "tfaz-kv"
}

variable "kv-sc-dc01-admin-label" {
  type    = string
  default = "VMadminNameDC01"
}

variable "kv-sc-dc01-adminuser" {
  type    = string
  default = "dc01admin"
}

variable "kv-sc-dc01-admin-pass-label" {
  type    = string
  default = "AdminPassDC01"
}

variable "tfaz-dc01-admin_upn" {
  type    = string
  default = "dc01admin@hemensarzalihotmail.onmicrosoft.com"
}

#variable "tfaz-keyvault-label" {
# type        = string
# default     = "tfaz-infra-kv"
#description = "description"
#}

#variable "tenant-id-label" {
#type    = string
#default = "kv-sc-tnt-id"
#}

#variable "subscription-id-label" {
#  type    = string
# default = "kv-sc-subid"
#}

#variable "spn-appId-label" {
# type    = string
#default = "kv-sc-appId-spn"
#}

###############################################################
# Virtual Network 1 
###############################################################

variable "tfaz-vnet1-label" {
  type    = string
  default = "tfaz-infra-vnet1"
}

variable "tfaz-vnet1-subnet1-addr-space" {
  type    = string
  default = "10.10.0.0/16"
}

variable "tfaz-infra-vnet1-subnet1-range" {
  type    = string
  default = "10.10.1.0/24"
}

variable "tfaz-vnet1-subnet1-label" {
  type    = string
  default = "tfaz-vnet1-subnet1"
}

###############################################################
# Virtual Network 2 
###############################################################

variable "tfaz-vnet2-label" {
  type    = string
  default = "tfaz-infra-vnet2"
}

variable "tfaz-vnet2-subnet1-addr-space" {
  type    = string
  default = "10.11.0.0/16"
}

variable "tfaz-vnet2-subnet1-range" {
  type    = string
  default = "10.11.1.0/24"
}

variable "tfaz-vnet2-subnet1-label" {
  type    = string
  default = "tfaz-vnet2-subnet1"
}

###############################################################
# VNet Peering 
###############################################################

variable "peering-vnet1--vnet2" {
  type    = string
  default = "peering-vnet--vnet2"
}

variable "peering-vnet2--vnet1" {
  type    = string
  default = "peering-vnet2--vnet1"
}

###############################################################
# Domain Name Services [DNS]
###############################################################

variable "tfaz-dns-servers-subn1" {
  type    = list(string)
  default = ["10.10.1.2", "168.63.129.16", "8.8.8.8"]
}

variable "tfaz-dns-servers-subn2" {
  type    = list(string)
  default = ["10.11.1.2", "168.63.129.16", "8.8.8.8"]
}

###############################################################
# Network Interface [DC01]
###############################################################

variable "dc01-netwint" {
  type    = string
  default = "tfaz-dcc01-netwint"
}

variable "tfaz-ipconfig" {
  type    = string
  default = "tfaz-netint-ipconfig-dc01"
}

variable "tfaz-netwint-priv-ip-dc01" {
  type    = string
  default = "10.10.1.101"
}

###############################################################
# 
###############################################################

###############################################################
# 
###############################################################

###############################################################
# 
###############################################################

###############################################################
# Virtual Machine DC01 Variables
###############################################################


variable "dc01-label" {
  description = "The name given to the vm"
  default     = "tfaz-infra-dc01"
}

variable "storage_account_type" {
  default = "Standard_LRS"
}

variable "vm_size" {
  description = "The size of the VM"
  default     = "Standard_D2_v3"
}
variable "storageimage_publisher" {
  description = "The OS image publisher"
  default     = "MicrosoftWindowsServer"
}
variable "storageimage_offer" {
  description = "The OS image offer"
  default     = "WindowsServer"
}
variable "storageimage_sku" {
  description = "The OS SKU"
  default     = "2019-datacenter"
}
variable "storageimage_version" {
  description = "The OS image version"
  default     = "latest"
}
variable "manageddisk_type" {
  description = "The managed disk type for the VM"
  default     = "Standard_LRS"
}

###############################################################
# Public IP Address
###############################################################

variable "PIP-dc01" {
  type    = string
  default = "tfaz-pip-dc01"
}

###############################################################
# Network Security Group
###############################################################

variable "NSG-AllowClient" {
  type    = string
  default = "tfaz-nsg-allow-client"
}

variable "sec-rule-allow-rdp-client" {
  type    = string
  default = "NSG-AllowClient-IP-SR-DC01"
}

###############################################################
# SPN Variables
###############################################################

variable "RoleAssinSPN" {
  type    = string
  default = "RoAssign-AllowSPNACreateADUser"
}

###############################################################
# 
###############################################################

###############################################################
# 
###############################################################

###############################################################
# 
###############################################################