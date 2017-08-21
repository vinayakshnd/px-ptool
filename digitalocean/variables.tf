# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

variable "public_key_fp" {
  description = "Fingerprint of the public key file"
}

variable "private_key_file" {
  description = "Location of the private key file"
  default = "~/.ssh/id_rsa"
}

variable "px_region" {
  default = "sfo2"
  description = "Digital Ocean region to create droplets"
}

variable "px_image"{
  default = "centos-7-x64"
  description = "Image to be used for all droplets"
}

variable "px_vm_size"{
  default = "2gb"
  description = "Droplet size"
}

variable "px_node_count" {
  default = 3
  description = "Number of worker droplets"
}

variable "user_prefix" {
  description = "Prefix to identify users resources, ideally a user-id"
}

variable "vm_admin_user" {
  description = "Admin user for the VM"
  default = "admuser"
}

variable "vm_admin_password" {
  description = "Password for admin user of VM"
  default = "s3cret"
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

variable "default_user" {
  description = "default user to log on to VM"
  default = "root"
}

variable "docker_image"{
  description = "Image of Portworx installation to be used"
  default = "portworx/px-enterprise:1.2.9"
}