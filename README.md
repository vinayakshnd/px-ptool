# Provisioning scripts for multiple clouds

This set of scripts can be used for following:

*  Specify Cloud, VM and Disk specific parameters as flags to `px_provision.sh`
*  Spawn instances and disks per specifications mentioned above
*  Mount required disks on their corresponding nodes.
*  Generate an output JSON file with node details.

## Pre-requisites

*  A terminal which works with bash. For windows machines, cygwin, mobaXterm or GitBash can be used.
*  Docker installation
*  Digital Ocean token to spawn droplets and volumes
*  GCP service account JSON file for access to GCP
*  Azure subscription ID, Client ID, Client Secret and Azure tenant ID. Following [link](https://www.terraform.io/docs/providers/azurerm/#creating-credentials-in-the-azure-portal) has all the details.


## Usage

`docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.0 <SUB COMMAND>`

### Sub Command Explanation:

`px_provision.sh` is the main script.
This script takes two positional parameters:

1.  Action (apply, destroy or reset)
2.  Cloud Name (digitalocean or gcp or azure)

Following are additional flags which are to be provided in case of `apply` or `reset`

`--region`      : Region in which the VMs and disks should be created

`--image`       : Single value in case of gcp and digitalocean, | Delimited string providing publisher, offer, sku and version in case of Azure

`--size`        : Size of VMs to be created

`--nodes`       : Number of VMs to be created

`--disks`       : Number of disks per node

`--disk_size`   : Size of each disk in GB

`--user_prefix` : Unique identifier for user's resources

Reset does a destroy followed by apply.

### Example : To create VMs and Disks on azure

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.0 \
./px_provision.sh apply azure \
--vm_creds 'poot|s3cretP@ss' \
--region 'West Europe' \
--image 'Canonical|UbuntuServer|14.04.2-LTS|latest' \
--size 'Standard_A1_V2' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'poot';
~~~

### Example : To create VMs and Disks on GCP

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.0 \
./px_provision.sh apply gcp \
--region 'us-central1|us-central1-a' \
--image 'ubuntu-os-cloud/ubuntu-1604-xenial-v20170330' \
--size 'n1-standard-1' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'bodie';
~~~

### Example : To create VMs and Disks on DigitalOcean

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.0 \
./px_provision.sh apply digitalocean \
--region 'sfo2' \
--image 'centos-7-x64' \
--size '2gb' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'bird';
~~~

### Example : TO destroy VMs and Disks

*  On Azure:
`px_provision.sh azure destroy --user_prefix 'poot'`

*  On DigitalOcean:
`px_provision.sh digitalocean destroy --user_prefix 'bird'`

*  On Google Cloud:
`px_provision.sh gcp destroy --user_prefix 'bodie'`


**Note for GCP** A service account must be created and the json file from this service account should be copied to gcp/credentials directory.
