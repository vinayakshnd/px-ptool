import argparse
import os
import subprocess
import uuid
import shutil
from jinja2 import Template
from do_functions import do_api_action
from azure_functions import gen_azure_json
from aws_functions import gen_aws_json


def get_args():
    """
    Function to parse and validate CLI
    :return: parse_args object
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['apply', 'destroy', 'reset'], action='store',
                        help='Action to be taken on cloud')
    parser.add_argument('cloud', choices=['digitalocean', 'gcp', 'azure', 'aws'], action='store',
                        help='The cloud on which to perform action')
    parser.add_argument('--vm_creds', action='store',
                        help='Username and password for the VMs separated by |')
    parser.add_argument('--region', action='store',
                        help='Region in which cloud resources will be created. Defaults to value in cloud specific variables.tf')
    parser.add_argument('--image', action='store',
                        help='OS Image to be used for VM, defaults to value in cloud specific variables.tf')
    parser.add_argument('--size', action='store',
                        help='Size of VM to be created. Defaults to size mentioned in cloud specific variables.tf')
    parser.add_argument('--nodes', default=2, action='store',
                        help='Number of VMs to create. Default : 2')
    parser.add_argument('--disks', default=[], action='store',
                        help='Comma separated list of Extra Disks to be created. Default : None')
    parser.add_argument('--user_prefix', required=True, action='store',
                        help='Unique user specific string. Should be a pure string less than 8 chars. Longer strings get truncated.')
    parser.add_argument('--swap_vol_size', action='store',
                        help="Size in GB of SWAP volume")
    parser.add_argument('--docker_vol_size', action='store',
                        help="Size in GB of docker volume")
    parser.add_argument('--disk1_vol_size', action='store',
                        help="Size in GB of Disk1 volume")
    parser.add_argument('--disk2_vol_size', action='store',
                        help="Size in GB of Disk2 volume")
    parser.add_argument('--install_px', default=True, action='store',
                        help="Install Portworx or not. True/False")
    parser.add_argument('--docker_image', action='store',
                        help="Docker image tag for portworx"),
    parser.add_argument('--setup_ecs', default=False, action='store',
                        help="Setup ECS cluster on AWS (Applicable wich ECS AMI). true/false")
    myargs = parser.parse_args()
    return myargs


def gen_tfvars(myargs):
    print "Action is {} Cloud is {} prefix is {}".format(myargs.action, myargs.cloud, myargs.user_prefix)
    px_ent_uuid = str(uuid.uuid4())
    if os.path.exists('{}/extra_disks.tf'.format(myargs.cloud)):
        os.remove('{}/extra_disks.tf'.format(myargs.cloud))
    with open('output/{}_{}_terraform.tfvars'.format(myargs.cloud, myargs.user_prefix), mode='w') as f:
        # Populating VM credentials if passed
        if myargs.vm_creds is not None:
            vm_admin_user, vm_admin_password = myargs.vm_creds.split('|')
            f.write('vm_admin_user = "{}"\n'.format(vm_admin_user))
            f.write('vm_admin_password = "{}"\n'.format(vm_admin_password))
        # Populating region if passed
        if myargs.region is not None:
            if myargs.cloud == 'azure' and '_' in myargs.region:
                myargs.region = myargs.region.replace('_', ' ')
            if myargs.cloud == 'gcp':
                gcp_region, gcp_region_zone = myargs.region.split('|')
                f.write('px_region = "{}"\n'.format(gcp_region))
                f.write('px_region_zone = "{}"\n'.format(gcp_region_zone))
            if myargs.cloud == 'aws':
                aws_region, aws_availability_zone = myargs.region.split('|')
                f.write('aws_region = "{}"\n'.format(aws_region))
                f.write('availability_zone = "{}"\n'.format(aws_availability_zone))
                if myargs.setup_ecs:
                    f.write('setup_ecs = true\n')
                    f.write('default_user = "ec2-user"\n')
            else:
                f.write('px_region = "{}"\n'.format(myargs.region))

        # Populating image details if passed
        if myargs.image is not None:
            if myargs.cloud == 'azure':
                a_pub, a_off, a_sku, a_ver = myargs.image.split('|')
                f.write('vm_image_publisher = "{}"\n'.format(a_pub))
                f.write('vm_image_offer = "{}"\n'.format(a_off))
                f.write('vm_image_sku = "{}"\n'.format(a_sku))
                f.write('vm_image_version = "{}"\n'.format(a_ver))
            else:
                f.write('px_image = "{}"\n'.format(myargs.image))
                if myargs.image == 'coreos-stable':
                    f.write('default_user = "core"\n')
        if myargs.size is not None:
            f.write('px_vm_size = "{}"\n'.format(myargs.size))
        if myargs.nodes > 0:
            f.write('px_node_count = "{}"\n'.format(myargs.nodes))
        if len(myargs.disks) > 0:
            print "Found extra disks"
            ds = [d.strip() for d in myargs.disks.split(',')]
            print "Disk sizes are found to be {}".format(ds)
            gen_extra_disks(myargs.cloud, ds)
        if myargs.swap_vol_size > 0:
            f.write('swap_vol_size = "{}"\n'.format(myargs.swap_vol_size))
        if myargs.docker_vol_size > 0:
            f.write('docker_vol_size = "{}"\n'.format(myargs.docker_vol_size))
        if myargs.disk1_vol_size > 0:
            f.write('disk1_vol_size = "{}"\n'.format(myargs.disk1_vol_size))
        if myargs.disk2_vol_size > 0:
            f.write('disk2_vol_size = "{}"\n'.format(myargs.disk2_vol_size))
        if 'docker' in myargs.user_prefix:
            raise RuntimeError("Using word docker is not allowed in prefix.")
        else:
            # Filtering any non alnum chars from prefix
            myprefix = ''.join([c for c in myargs.user_prefix if c.isalnum()])
            f.write('user_prefix = "{}"\n'.format(myprefix))
        f.write('px_ent_uuid = "{}"\n'.format(px_ent_uuid))
        if myargs.docker_image is not None:
            f.write('docker_image = "{}"'.format(myargs.docker_image))


def gen_creds(myargs):

    with open('{}/creds.tfvars'.format(myargs.cloud), mode='w') as credfile:
        if myargs.cloud == 'digitalocean':
            credfile.write('do_token = "{}"\n'.format(os.getenv('TF_VAR_do_token')))
            credfile.write('public_key_fp = "{}"\n'.format(os.getenv('DO_PUBKEY_FP')))
        if myargs.cloud == 'gcp':
            with open('gcp/credentials/terraform.tfvars',mode='w') as sa_json:
                sa_json.write(os.getenv('GCP_SA_JSON'))
            credfile.write('project = "{}"\n'.format(os.getenv('GCP_PROJECT')))
            credfile.write('credentials_file_path = "credentials/terraform.json"\n')
        if myargs.cloud == 'azure':
            credfile.write('azure_subscription_id = "{}"\n'.format(os.getenv('TF_VAR_azure_subscription_id')))
            credfile.write('azure_client_id = "{}"\n'.format(os.getenv('TF_VAR_azure_client_id')))
            credfile.write('azure_client_secret = "{}"\n'.format(os.getenv('TF_VAR_azure_client_secret')))
            credfile.write('azure_tenant_id = "{}"\n'.format(os.getenv('TF_VAR_azure_tenant_id')))
        if myargs.cloud == 'aws':
            credfile.write('aws_access_key = "{}"\n'.format(os.getenv('TF_VAR_aws_access_key')))
            credfile.write('aws_secret_key = "{}"\n'.format(os.getenv('TF_VAR_aws_secret_key')))
            credfile.write('px_key_name = "{}"\n'.format(os.getenv('TF_VAR_aws_key')))


def gen_extra_disks(mycloud, dlist):
    """
    Function to generate dynamic disk tf files
    :param mycloud: name of cloud
    :param dlist: list of disk sizes
    :return:
    """
    mycount = 1
    if mycloud == 'digitalocean':
        do_disk_tpl = Template("""
        resource "digitalocean_volume" "do-xdisk{{ idx }}-vol" {
          count = "${var.px_node_count}"
          region      = "${var.px_region}"
          name        = "${format("do-%s-xdisk{{ idx }}-vol-%d", var.user_prefix, count.index + 1)}"
          size        = "{{ disk_size }}"
          description = "px digitalocean xtra disk {{ idx }} volume"
        }
            """)
        with open('digitalocean/extra_disks.tf', 'w') as xtradisk:
            for d in dlist:
                if d != '':
                    xtradisk.write(do_disk_tpl.render(disk_size=d, idx=mycount))
                    mycount += 1
    if mycloud == 'gcp':
        gcp_disk_tpl = Template("""
resource "google_compute_disk" "gcp-xdisk{{ idx }}-pd" {
  count = "${var.px_node_count}"
  name = "${format("px-gcp-%s-xdisk{{ idx }}-%d", var.user_prefix, count.index + 1)}"
  zone = "${var.px_region_zone}"
  size = "{{ disk_size }}"
}
        """)
        with open('gcp/extra_disks.tf', mode='w') as xtradisk:
            for d in dlist:
                if d != '':
                    xtradisk.write(gcp_disk_tpl.render(disk_size=d, idx=mycount))
                    mycount += 1
    if mycloud == 'azure':
        shutil.copy2('azure/instances.tf.tpl', 'azure/instances.tf')
        azure_disk_tpl = Template("""
  storage_data_disk {
    name          = "azure-${var.user_prefix}-xdisk-${count.index + 1}"
    vhd_uri       = "${azurerm_storage_account.astgacc.primary_blob_endpoint}${azurerm_storage_container.astgctnr.name}/azure-${var.user_prefix}-xdisk-${count.index + 1}"
    disk_size_gb  = "{{ disk_size }}"
    create_option = "Empty"
    lun           = "{{ idx }}"
  }
        """)
        az_disks = ''
        for d in dlist:
            if d != '':
                az_disks = az_disks + azure_disk_tpl.render(disk_size=d, idx=3+mycount)
                mycount += 1
        print "Azure disks are \n {}".format(az_disks)
        with open('azure/instances.tf', mode='r') as azfile:
            az_inst = azfile.read()
        az_inst = az_inst.replace('/*DO_NO_REMOVE_THIS_COMMENT*/', az_disks)
        with open('azure/instances.tf', mode='w') as azfile:
            azfile.write(az_inst)
    if mycloud == 'aws':
        aws_disk_tpl = Template("""
        resource "aws_ebs_volume" "px-xdisk{{ idx }}-vol" {
          count = "${var.px_node_count}"
          availability_zone  = "${var.availability_zone}"
          size        = "{{ disk_size }}"
        }

        resource "aws_volume_attachment" "xdisk{{ idx }}_vol_attach" {
            device_name = "/dev/sdd"
            count = "${var.px_node_count}"
            volume_id   = "${element(aws_ebs_volume.px_xdisk{{ idx }}_vol.*.id, count.index)}"
            instance_id = "${element(aws_instance.px-node.*.id, count.index)}"
        }    
        """)
        with open('aws/extra_disks.tf', 'w') as xtradisk:
            for d in dlist:
                if d != '':
                    xtradisk.write(aws_disk_tpl.render(disk_size=d, idx=mycount))
                    mycount += 1

def tf_apply(mycloud, myprefix, install_px):
    """
    Function to run terraform apply
    :param mycloud: Name of cloud
    :param myprefix: Unique identifier of resources
    :return: None
    """
    os.chdir(mycloud)
    tf_cmd = 'terraform apply -no-color ' \
             '-var-file creds.tfvars ' \
             '-var-file ../output/{}_{}_terraform.tfvars ' \
             '-state ../output/{}_{}.tfstate'.format(mycloud, myprefix, mycloud, myprefix)
    subprocess.check_call(tf_cmd, shell=True)
    os.chdir(script_loc)
    if mycloud == 'digitalocean':
        # Call do_api_action function
        do_api_action('attach', myprefix, install_px)
    if mycloud == 'azure':
        gen_azure_json(myprefix, install_px)
    if mycloud == 'aws':
        gen_aws_json(myprefix, install_px)


def tf_destroy(mycloud, myprefix):
    if mycloud == 'digitalocean':
        do_api_action('detach', myprefix, False)
    tf_cmd = 'terraform destroy -no-color -force ' \
             '-var-file creds.tfvars ' \
             '-var-file {}/output/{}_{}_terraform.tfvars ' \
             '-state {}/output/{}_{}.tfstate'.format(script_loc, mycloud, myprefix, script_loc, mycloud, myprefix)
    os.chdir(mycloud)
    subprocess.check_call(tf_cmd, shell=True)
    os.chdir(script_loc)


#
# Main Starts here
#
if __name__ == '__main__':
    args = get_args()
    gen_creds(args)
    script_loc = os.getcwd()
    if args.action == 'destroy' or args.action == 'reset':
        tf_destroy(args.cloud, args.user_prefix)
    if args.action == 'apply' or args.action == 'reset':
        gen_tfvars(args)
        tf_apply(args.cloud, args.user_prefix, args.install_px)


