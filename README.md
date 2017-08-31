# Provisioning container for multiple clouds

This container can be used for following:

*  Specify Cloud, VM and Disk specific parameters as flags to `px_provision.sh`
*  Spawn instances and disks per specifications mentioned above
*  Mount required disks on their corresponding nodes.
*  Generate an output JSON file with node details.

## Pre-requisites

*  A terminal which works with bash. For windows machines, cygwin, mobaXterm or GitBash can be used.
*  SSH key pair to be copied to `keys` directory of this repository. The public and private keys should be named id_rsa.pub and id_rsa respectively. This keypair will be used to log on to VMs of GCP.For DigitalOcean, manually upload the keypair, get the fingerprint of the key and specify it in Dockerfile as DO_PUBKEY_FP  ENV variable.
*  Docker installation
*  Digital Ocean token to spawn droplets and volumes
*  Import ssh key of step 2 in DigitalOcean
*  GCP service account JSON file for access to GCP
*  Azure subscription ID, Client ID, Client Secret and Azure tenant ID. Following [link](https://www.terraform.io/docs/providers/azurerm/#creating-credentials-in-the-azure-portal) has all the details.


## Usage

`docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.4 <SUB COMMAND>`

### Sub Command Explanation:

`px_provision.sh` is the main script.
This script takes two positional parameters:

1.  Action (apply, destroy, reset, or pxify)
2.  Cloud Name (digitalocean or gcp or azure)

Following are additional flags which are to be provided in case of `apply` or `reset`

`--region`      : Region in which the VMs and disks should be created

`--image`       : Single value in case of gcp and digitalocean, | Delimited string providing publisher, offer, sku and version in case of Azure

`--size`        : Size of VMs to be created

`--nodes`       : Number of VMs to be created

`--disks`       : Number of disks per node

`--disk_size`   : Size of each disk in GB

`--user_prefix` : Unique identifier for user's resources

**Azure Only**
`--vm_creds`    : '|' separated username and password to be used on azure nodes.

Reset does a destroy followed by apply.

**AWS and Azure Only**
Pxify takes an existing Tectonic cluster deployed on AWS, and makes it ready for Portworx to deploy.

### Example : To create VMs and Disks on azure

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.4 ./px_provision.sh apply azure \
--vm_creds 'nodeadm|s3cretP@ss' \
--region 'West Europe' \
--image 'Canonical|UbuntuServer|14.04.2-LTS|latest' \
--size 'Standard_A1_V2' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'deangelo'
~~~

### Example : To create VMs and Disks on GCP

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.3 ./px_provision.sh apply gcp \
--region 'us-central1|us-central1-a' \
--image 'ubuntu-os-cloud/ubuntu-1604-xenial-v20170330' \
--size 'n1-standard-1' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'weebey'
~~~

### Example : To create VMs and Disks on DigitalOcean

~~~
docker run -v ${PWD}/output:/root/px_prov/output infracloud/px_prov:1.3 ./px_provision.sh apply digitalocean \
--region 'sfo2' \
--image 'centos-7-x64' \
--size '2gb' \
--nodes 2 \
--disks 2 \
--disk_size 10 \
--user_prefix 'savino'
~~~

### Example : TO destroy VMs and Disks

*  On Azure:
`px_provision.sh azure destroy --user_prefix 'deangelo'`

*  On DigitalOcean:
`px_provision.sh digitalocean destroy --user_prefix 'savino'`

*  On Google Cloud:
`px_provision.sh gcp destroy --user_prefix 'weebey'`


**Note for GCP** A service account must be created and the json file from this service account should be copied to gcp/credentials directory.

### Example:  Post-processing for a Tectonic cluster, to be ready for Portworx to deploy

* On AWS

To take a cluster that has been successfully deployed through Tectonic, 
and then add 3 100GB disks to each worker node:

```
px_provision.sh pxify aws --aws_access_key_id $AWS_ACCESS_KEY_ID         \
                          --aws_secret_access_key $AWS_SECRET_ACCESS_KEY \
                          --disks 3 --disk_size 100                      \
                          --region $AWS_DEFAULT_REGION                   \
                          --aws_cluster $AWS_CLUSTER
```
where $AWS_CLUSTER corresponds to the Tectonic $CLUSTER variable, which gets used as the basename for the AWS auto-scaling groups, (i.e. "$CLUSTER-master" and "$CLUSTER-worker")

* On Azure

To take a cluster that has been successfully deployed through Tectonic, 
and then add 2 100GB disks to each worker node, running:

```
docker run px-ptool ./px_provision.sh pxify azure --arm_client_id $ARM_CLIENT_ID             \
                               --arm_subscription_id $ARM_SUBSCRIPTION_ID \
                               --arm_client_secret $ARM_CLIENT_SECRET     \
                               --arm_tenant_id $ARM_TENANT_ID             \
                               --region $ARM_REGION                       \
                               --arm_cluster $CLUSTER                     \
                               --disks 2                                  \
                               --disk_size 100
```

should produce output similar to :

```
VMs for jefftonic2-worker =
    vm :  jefftonic2-worker-0
    vm :  jefftonic2-worker-1
    vm :  jefftonic2-worker-2
VMs for jefftonic2-master =
    vm :  jefftonic2-master-0
ID: /subscriptions/72c299a4-a431-4b8e-80ef-6855109979d9/resourceGroups/tectonic-cluster-jefftonic2/providers/Microsoft.Storage/storageAccounts/worker9e1cbfb6, Name: worker9e1cbfb6, Kind: Storage
     Attach Data Disk : jefftonic2-worker-0  2 , size = 100
     Attach Data Disk : jefftonic2-worker-1  2 , size = 100
     Attach Data Disk : jefftonic2-worker-2  2 , size = 100
Adding security rule with port :  9001 pxport-9001
Adding security rule with port :  9002 pxport-9002
Adding security rule with port :  9003 pxport-9003
Adding security rule with port :  9010 pxport-9010
Adding security rule with port :  9012 pxport-9012
Adding security rule with port :  9014 pxport-9014
Adding LH security rule with port :  30062 px-port-LH
```
