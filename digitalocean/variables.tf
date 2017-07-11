# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

variable "public_key_file" {
  description = "Location of the public key file"
  default = "~/.ssh/id_rsa.pub"
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

variable "px_disk_count" {
  default = 3
  description = "Number of disks per node"
}

variable "px_disk_size" {
  default = 10
  description = "Size of volumes to be created"
}

variable "user_prefix" {
  description = "Prefix to identify users resources, ideally a user-id"
}