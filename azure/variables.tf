variable "px_region" {
  default = "West Europe"
}

variable "user_prefix" {
  description = "Unique user prefix"
}

variable "px_node_count" {
  default = 2
  description = "Number of VMs to create"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
}

variable "azure_client_id" {
  description = "Azure client ID"
}

variable "azure_client_secret" {
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  description = "Azure tenant id"
}

variable "px_vm_size" {
  description = "Size of Azure VM"
  default = "Standard_A2_v2"
}

variable "vm_image_publisher" {
  description = "Publisher of VM image"
  default = "Canonical"
}

variable "vm_image_offer" {
  description = "VM image offer"
  default = "UbuntuServer"
}

variable "vm_image_sku" {
  description = "VM image SKU"
  default = "14.04.2-LTS"
}

variable "vm_image_version" {
  description = "VM image version"
  default = "latest"
}

variable "vm_admin_user" {
  description = "VM admin user"
  default = "admuser"
}

variable "vm_admin_password" {
  description = "VM admin password"
  default = "S3cret"
}

variable "swap_vol_size" {
  description = "Size in GB of SWAP volume"
  default = 8
}

variable "docker_vol_size" {
  description = "Size in GB of Docker volume"
  default = 64
}

variable "disk1_vol_size" {
  description = "Size in GB of disk1 volume"
  default = 128
}

variable "disk2_vol_size" {
  description = "Size in GB of disk1 volume"
  default = 64
}

variable "px_ent_uuid" {
  description = "UUID of Portworx Enterprise cluster"
  default = "00000000-0000-0000-0000-000000000000"
}

variable "admin_pubkey_data" {
  description = "Content of public key for admin user"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKCI+pMSCqj38yXNXjRKbhjD8RyXnO8HD2EI7yLJLKQ70Emt0BuVeef7Or9XHdwh7RkUBH+1NqbAW7d3So7FK3nAU9NxMfCMNtIDoNV2Y/yI32ipcWsXHqA+LOWUkqIKwOfL2aoCsXfAzxDFIdt+rVgHu9FYUmpSPcaqaUxuFMATHEVc3fQSraWiofO59v6Ha9nXNW691OWABiglIOfsOQ1P+rwZUHMhbIdhHL9jae7VapYhwVXNgytYTGG403c0nJ3Msh4GwH+2oI8L4Ls4usfX/6hXgiBIOkfqwYeoYDlI07chXeDoHzvMjsZZ645sXT6Esv5mLuC7GMU1qChW1X infracloud@VISHAL-B"
}