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

variable "px_disk_count" {
  default = 1
  description = "Number of disks to add to each VM"
}

variable "px_disk_size" {
  default = 10
  description = "Size of mounted disks in GB"
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
  default = "Standard_A0"
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
  default = "admin"
}

variable "vm_admin_password" {
  description = "VM admin password"
  default = "Password1234!"
}