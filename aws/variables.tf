# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "px_node_count" {
  default = 3
  description = "Number of AWS instances"
}

variable "aws_region" {
  description = "AWS region in which to deploy ECS cluster"
  default = "us-east-1"
}

variable "availability_zone" {
  description = "AWS availability zone in which to deploy ECS cluster"
  default = "us-east-1b"
}

variable "ssh_key" {
  description = "SSH key to use to embed in EC2 instances."
  default = "vinayak"
}

variable "px_vm_size" {
  description = "Size of AWS EC2 VM"
  default = "t2.large"
}

variable "px_key_name" {
  description = "default user to log on to VM"
  default = "px_ptool"
}

variable "px_ent_uuid" {
  description = "UUID of Portworx Enterprise cluster"
  default = "00000000-0000-0000-0000-000000000000"
}

variable "default_user" {
  description = "default user to log on to VM"
  default = "centos"
}

variable "private_key_file" {
  description = "Location of the private key file"
  default = "/root/.ssh/id_rsa_px"
}

variable "user_prefix" {
  description = "Unique user prefix"
  default = "ecs"
}

variable "vm_admin_user" {
  description = "Admin user for the VM"
  default = "admuser"
}

variable "vm_admin_password" {
  description = "Password for admin user of VM"
  default = "s3cret"
}

variable "docker_image"{
  description = "Image of Portworx installation to be used"
  default = "portworx/px-enterprise:1.2.9"
}

variable "px_image" {
	description = "Name of the AMI for EC2 compute instances"
	default		  = "ami-ec33cc96"
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

variable "setup_ecs" {
	description = "Flag to determine whether to setup ECS cluster"
	default		  = 0
}