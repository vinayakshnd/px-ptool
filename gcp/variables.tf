variable "region" {
  description = "Region of GCE resources"
  default     = "us-central1"
}

variable "region_zone" {
  description = "Region and Zone of GCE resources"
  default     = "us-central1-a"
}

variable "project" {
	 description = "Name of GCE project"
	 default     = "dummydefault"
}

variable "machine_type" {
	description = "Type of VM to be created"
	default 		= "n1-standard-1"
}
variable "image" {
	description = "Name of the OS image for compute instances"
	default		  = "ubuntu-os-cloud/ubuntu-1604-xenial-v20170330"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "credentials/account.json"
}

variable "public_key_path" {
  description = "Path to file containing public key"
  default     = "credentials/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to file containing private key"
  default     = "credentials/id_rsa"
}

variable "user_prefix" {
  description = "Unique identifier for a users resources"

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
