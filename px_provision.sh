#!/usr/bin/env bash
set -e
#set -x

SUPPORTED_CLOUDS="digitalocean gcp azure"

show_usage() {

echo "Usage : $0 [apply|destroy|reset] [gcp|azure|digitalocean] [additional flags]";
echo "Additional Flags:";
echo "--auth        : Access token in case of digitalocean,| delimited string with project name and path to service account json file for gcp and | delimited string with AZURE_SUBSCRIPTION_ID,AZURE_CLIENT_ID,AZURE_CLIENT_SECRET,AZURE_TENANT_ID for azure";
echo "--vm_creds    : | delimited string with public and private key for gcp and digitalocean, username and password for azure";
echo "--region      : Region in which the VMs and disks should be created";
echo "--image       : Single value in case of gcp and digitalocean, Delimited string providing publisher, offer, sku and version in case of Azure";
echo "--size        : Size of VMs to be created";
echo "--nodes       : Number of VMs to be created";
echo "--disks       : Number of disks per node";
echo "--disk_size   : Size of each disk in GB";
echo "--user_prefix : Unique identifier for user's resources"

exit 1;
}

check_cloud(){
    for c in $SUPPORTED_CLOUDS
    do
        if [[ "$1" == "${c}" ]]; then
            supported=0;
        fi
    done

}

check_tf(){
#
# Checking if terraform is available

terraform --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: terraform not found. Please ensure terraform is available in PATH ";
    exit 1;
fi

}

validate_params(){

    paramList=( auth vm_creds region image size nodes disks disk_size user_prefix )
    missingParams=()
    for param in "${paramList[@]}"
    do
        : 
        if [ -z ${!param} ]
        then
            missingParams+=("$param")
        fi       
    done

    if [ ${#missingParams[@]} -ne 0 ]
    then
        echo "ERROR: Bellow additional flags are missing:"
        (IFS=,; echo "${missingParams[*]}");
        show_usage
    fi
}

split_params() {
#
# Create cloud specific variables

if [[ "$cloud" == "digitalocean" || "$cloud" == "gcp" ]]; then
    vm_pub_key=$(echo $vm_creds | cut -d "|" -f1);
    vm_pri_key=$(echo $vm_creds | cut -d "|" -f2);

fi

if [[ "${cloud}" == "gcp" ]]; then

    gcp_project=$(echo $auth | cut -d "|" -f1);
    gcp_sa_json=$(echo $auth | cut -d "|" -f2);
    gcp_region=$(echo $region | cut -d "|" -f1);
    gcp_region_zone=$(echo $region | cut -d "|" -f2);
fi

if [[ "$cloud" == "azure" ]]; then
    azure_sub_id=$(echo $auth | cut -d "|" -f1);
    azure_client_id=$(echo $auth | cut -d "|" -f2);
    azure_client_secret=$(echo $auth | cut -d "|" -f3);
    azure_tenant_id=$(echo $auth | cut -d "|" -f4);
    azure_image_pub=$(echo $image | cut -d "|" -f1);
    azure_image_offer=$(echo $image | cut -d "|" -f2);
    azure_image_sku=$(echo $image | cut -d "|" -f3);
    azure_image_version=$(echo $image | cut -d "|" -f4);
    azure_vm_user=$(echo $vm_creds | cut -d "|" -f1);
    azure_vm_pass=$(echo $vm_creds | cut -d "|" -f2);

fi

}

gen_tfvars(){

split_params;
cd $scriptLoc;
if [[ "${cloud}" == "digitalocean" ]]; then

cat <<EOF > digitalocean/terraform.tfvars
do_token = "${auth}"
public_key_file = "${vm_pub_key}"
private_key_file = "${vm_pri_key}"
px_region = "${region}"
px_image = "${image}"
px_vm_size = "${size}"
px_node_count = ${nodes}
px_disk_count = ${disks}
px_disk_size = ${disk_size}
user_prefix = "${user_prefix}"
EOF

fi

if [[ "${cloud}" == "gcp" ]]; then
cat <<EOF > gcp/terraform.tfvars
project = "${gcp_project}"
credentials_file_path = "${gcp_sa_json}"
px_region = "${gcp_region}"
px_region_zone = "${gcp_region_zone}"
public_key_path = "${vm_pub_key}"
private_key_path = "${vm_pri_key}"
px_image = "${image}"
px_vm_size = "${size}"
px_node_count = ${nodes}
px_disk_count = ${disks}
px_disk_size = ${disk_size}
user_prefix = "${user_prefix}"

EOF
fi

if [[ "${cloud}" == "azure" ]]; then

cat <<EOF > azure/terraform.tfvars
azure_subscription_id = "${azure_sub_id}"
azure_client_id = "${azure_client_id}"
azure_client_secret = "${azure_client_secret}"
azure_tenant_id = "${azure_tenant_id}"
px_region = "${region}"
vm_image_publisher = "${azure_image_pub}"
vm_image_offer = "${azure_image_offer}"
vm_image_sku = "${azure_image_sku}"
vm_image_version = "${azure_image_version}"
vm_admin_user = "${azure_vm_user}"
vm_admin_password = "${azure_vm_pass}"
px_vm_size = "${size}"
px_node_count = ${nodes}
px_disk_count = ${disks}
px_disk_size = ${disk_size}
user_prefix = "${user_prefix}"
EOF
fi

}

add_azure_disks(){

disks_count=$1;
inst_file=azure/instances.tf

cp -f ${inst_file}.tpl ${inst_file};
#
# Remove last char from instances.tf
sed -i '$ s/.$//' ${inst_file}
for d in $(seq ${disks_count})
do
  cat<<EOF >> ${inst_file}
  storage_data_disk {
    name          = "datadisk\${var.user_prefix}\${count.index + 1}${d}"
    vhd_uri       = "\${azurerm_storage_account.astgacc.primary_blob_endpoint}\${azurerm_storage_container.astgctnr.name}/datadisk\${var.user_prefix}\${count.index + 1}${d}.vhd"
    disk_size_gb  = "\${var.px_disk_size}"
    create_option = "Empty"
    lun           = "$(( $d - 1 ))"
  }

EOF
done

echo "}" >> ${inst_file}

}


destroy(){

    cd $scriptLoc;
    if [[ "${cloud}" == "digitalocean" ]]; then
        python digitalocean/scripts/do_api_action.py detach
    fi
    if [[ "${cloud}" == "gcp" ]]; then
         python gcp/scripts/gcp_api_action.py detach;
    fi
     cd $cloud;
     terraform destroy -force;
}

#
# Main starts here
#

check_tf;
scriptLoc=$PWD;
action=$1;
shift;
if [[ "$action" != "apply" && "$action" != "destroy" && "$action" != "reset" ]]; then
     echo "ERROR : Action $action is not supported";
     show_usage
fi

cloud=$1;
shift;

supported=1
check_cloud $cloud
if [[ $supported -ne 0 ]]; then
    echo "ERROR : Cloud $cloud is not supported";
    show_usage
fi
if [[ "$action" == "apply" || "$action" == "reset" ]]; then
    if [[ "$action" == "reset" ]]; then
        destroy;
    fi

    while [ "$1" != "" ];
    do
        case $1 in
            --auth )
                auth=$2;
                shift;
                shift;;
            --vm_creds )
                vm_creds=$2;
                shift;
                shift;;
            --region )
                region=$2;
                shift;
                shift;;
            --image )
                image=$2;
                shift;
                shift;;
            --size )
                size=$2;
                shift;
                shift;;
            --nodes )
                nodes=$2;
                shift;
                shift;;
            --disks )
                disks=$2;
                shift;
                shift;;
            --disk_size )
                disk_size=$2;
                shift;
                shift;;
            --user_prefix )
                user_prefix=$2;
                shift;
                shift;;
            * )
                echo "ERROR : Parameter $1 is not supported";
                show_usage;;
        esac
    done
    validate_params
    gen_tfvars;
    if [[ "${cloud}" == "azure" ]]; then
        disks=$(grep "^px_disk_count" ${cloud}/terraform.tfvars | cut -d"=" -f2 | tr -cd '[:alnum:]')
        add_azure_disks $disks
    fi
    cd $cloud;
    terraform apply;
    cd $scriptLoc;
    #
    # Trigger Post actions
    #
    if [[ "${cloud}" == "digitalocean" ]]; then
        python digitalocean/scripts/do_api_action.py attach;
        echo "=======================================================================";
        echo "   The JSON output file is digitalocean_output.json";
        echo "=======================================================================";

    fi

    if [[ "${cloud}" == "gcp" ]]; then
        python gcp/scripts/gcp_api_action.py attach;
        echo "=======================================================================";
        echo "   The JSON output file is gcp_output.json";
        echo "=======================================================================";

    fi

#
# Generate a YAML to get tfshow output,
# this workaround is in place because of this bug
# https://github.com/hashicorp/terraform/issues/6634
#
    if [[ "${cloud}" == "azure" ]]; then
        cd azure;
        terraform apply > /dev/null 2>&1
        terraform show -no-color | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | sed "s/ = /: /g" > tfshow.yaml
        cd $scriptLoc;
        python azure/scripts/azure_json.py
        echo "=======================================================================";
        echo "   The JSON output file is azure_output.json";
        echo "=======================================================================";

    fi

fi

if [[ "${action}" == "destroy" ]]; then
    destroy
fi
