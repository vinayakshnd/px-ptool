# Provisioning scripts for multiple clouds

This set of scripts can be used for following:

*  Define Cloud, VM and Disk specific parameters in appropriate sections of `config.yaml`
*  Spawn instances and disks per specifications mentioned above
*  Mount required disks on their corresponding nodes.
*  Generate an output JSON file with node details.

## Pre-requisites

*  A terminal which works with bash. For windows machines, cygwin, mobaXterm or GitBash can be used.
*  Python 2.7 and pip.
*  Go to repository location and run `pip install -r requirements.txt`
*  Digital Ocean token to spawn droplets and volumes
*  GCP service account JSON file for access to GCP
*  Azure subscription ID, Client ID, Client Secret and Azure tenant ID. Following [link](https://www.terraform.io/docs/providers/azurerm/#creating-credentials-in-the-azure-portal) has all the details.


## Usage

`px_prov.sh` is the main script.
This script takes two parameters:

1.  Cloud Name (digitalocean or gcp or azure)
2.  Action (apply or destroy)

### Example : To create VMs and Disks
`px_prov.sh digitalocean apply`

### Example : TO destroy VMs and Disks
`px_prov.sh gcp destroy`

## Configuration Details

`config.yaml` is the main config file.
This file contains one section per cloud provider.
Parameters can be changed as per requirement.

**Note for GCP** A service account must be created and the json file from this service account should be copied to gcp/credentials directory.