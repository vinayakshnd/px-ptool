# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

variable "public_key_file" {
  description = "Location of the public key file"
}

variable "private_key_file" {
  description = "Location of the private key file"
}

variable "do-region" {
  default = "sfo2"
  description = "Digital Ocean region to create droplets"
}

variable "do-image"{
  default = "centos-7-x64"
  description = "Image to be used for all droplets"
}

variable "px-node-size"{
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

variable "px-disk-size" {
  default = 10
  description = "Size of volumes to be created"
}

variable "user_prefix" {
  description = "Prefix to identify users resources, ideally a user-id"
}