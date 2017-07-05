#!/usr/bin/env bash

set -e
#
# Script to provision cloud resources
# Usage:
# $0 <Cloud Name> <apply|destroy>
#

SUPPORTED_CLOUDS="digitalocean gcp azure"

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
    disk_size_gb  = "\${var.disk_size}"
    create_option = "Empty"
    lun           = "$(( $d - 1 ))"
  }

EOF
done

echo "}" >> ${inst_file}


}

check_cloud(){
    for c in $SUPPORTED_CLOUDS
    do
        if [[ "$1" == "${c}" ]]; then
            supported=0;
        fi
    done

}

show_usage(){
    echo "Usage: $0 <Cloud Name> <apply | destroy>";
    echo "Supported Clouds are $SUPPORTED_CLOUDS ";
    echo "apply : creates requested resources on specified cloud";
    echo "destroy: creates requested resources on specified cloud";
    exit 1;

}


#
# Main starts here
#

cloud=$1;
action=$2;
scriptLoc=$PWD;

if [[ ! -a config.yaml ]]; then
    echo "ERROR: config.yaml file is missing from $PWD";
    exit 1;
fi

if [[ "$1" == "" || "$2" == "" ]];then
    echo "ERROR: Incorrect parameters specified";
    show_usage
fi
supported=1
check_cloud $cloud
if [[ $supported -ne 0 ]]; then
    echo "ERROR : Cloud $cloud is not supported";
    show_usage
fi

if [[ "$action" != "apply" && "$action" != "destroy" ]]; then
    echo "ERROR : Only apply and destroy actions are allowed";
    show_usage
fi

if [[ "$action" == "apply" ]]; then
    echo "INFO : Generating terraform.tfvars for $cloud";
    python ${scriptLoc}/gen_tfvars_yaml.py $cloud

    if [[ "${cloud}" == "azure" ]]; then
        disks=$(grep "^disk_count" ${cloud}/terraform.tfvars | cut -d"=" -f2 | tr -cd '[:alnum:]')
        add_azure_disks $disks
    fi
    echo "INFO : triggering terraform apply";
    cd $cloud;
    terraform apply
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
        terraform show | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" | sed "s/ = /: /g" > tfshow.yaml
        cd $scriptLoc;
        python azure/scripts/azure_json.py
        echo "=======================================================================";
        echo "   The JSON output file is azure_output.json";
        echo "=======================================================================";

    fi

fi

if [[ "$action" == "destroy" ]]; then
    cd $scriptLoc;
    if [[ "${cloud}" == "digitalocean" ]]; then
        python digitalocean/scripts/do_api_action.py detach
    fi
    if [[ "${cloud}" == "gcp" ]]; then
         python gcp/scripts/gcp_api_action.py detach;
    fi
     cd $cloud;
     terraform destroy;
fi