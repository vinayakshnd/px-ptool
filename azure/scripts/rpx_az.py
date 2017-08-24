#!/usr/bin/env python3.6
import os
import sys
from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.compute.models import DiskCreateOption
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.network.models import SecurityRule,            \
                                      SecurityRuleAccess,      \
                                      SecurityRuleDirection,   \
                                      SecurityRuleProtocol,    \
                                      NetworkSecurityGroup 

#
# Required
#
envars = ["ARM_SUBSCRIPTION_ID", "ARM_CLIENT_ID",
          "ARM_CLIENT_SECRET", "ARM_TENANT_ID", "ARM_REGION",
          "ARM_NUM_VOLS", "ARM_VOL_SIZE", "CLUSTER"]

#
# Need to poke holes for these ports in the worker nsg
#
Pxports = [9001, 9002, 9003, 9010, 9012, 9014]


def check_env():
    for e in envars:
        if not os.getenv(e):
            print("ERROR: %s must be set in the environmet" % e)
            sys.exit(1)


def get_vms(rg, avset_name):
    vms = []
    for vm in compute_client.virtual_machines.list(rg):
        if avset_name in vm.name:
            vms.append(vm.name)
    return vms


# Get storage account name for workers
def get_storage_acct(rg):
    for item in resource_client.resource_groups.list_resources(rg):
        if item.kind == "Storage" and "worker" in item.name:
            print("ID: %s, Name: %s, Kind: %s" %
                  (item.id, item.name, item.kind))
            storage_acct = storage_client.storage_accounts.get_properties(
                resource_group,
                item.name
            )
    return storage_acct


def mk_data_disks(vmname, size, numdisks, storage_acct):
    data_disks = []
    for d in range(0, numdisks):
        diskname = vmname + "-pxdisk-" + str(d)
        disk = {
            'name': diskname,
            'disk_size_gb': size,
            'lun': d,
            'vhd': {
                'uri': "http://{}.blob.core.windows.net/pxvhds/{}.vhd".format(
                    storage_acct.name, diskname)
            },
            'create_option': 'Empty'
        }
        data_disks.append(disk)
    return data_disks


def attach_data_disk(rg, vmname, region, numdisks, size, storage_acct):
    # Attach data disk
    print("     Attach Data Disk : %s  %d , size = %d" %
          (vmname, numdisks, size))
    async_vm_update = compute_client.virtual_machines.create_or_update(
        resource_group,
        vmname,
        {
            'location': region,
            'storage_profile': {
                'data_disks': mk_data_disks(vmname,
                                            size,
                                            numdisks,
                                            storage_acct)
            }
        }
    )
    #  async_vm_update.wait()


# Make list of security rules, with holes for PX ports
def make_worker_rules(worker_subnet):
    # get existing rules
    security_rules = list(network_client.security_rules.list(
        resource_group,
        worker_basename
    ))

    # find lowest existing priorioty
    low_prio = 0
    for s in security_rules:
        if s.priority > low_prio and s.direction == 'Inbound':
            low_prio = s.priority

    for p in Pxports:
        prio = low_prio + Pxports.index(p) + 1
        rule_name = 'pxport-{}'.format(p)
        print("Adding security rule with port : ", p, rule_name)
        async_security_rule = network_client.security_rules.create_or_update(
            resource_group,
            worker_basename,
            rule_name,
            {
                'access': SecurityRuleAccess.allow,
                'description': 'Portworx security rule',
                'destination_address_prefix': '*',
                'destination_port_range': p,
                'direction': SecurityRuleDirection.inbound,
                'priority': prio,
                'protocol': SecurityRuleProtocol.tcp,
                'source_address_prefix': worker_subnet.address_prefix,
                'source_port_range': p
            }
        )
        async_security_rule.wait()


# Master Network Security Group just needs output for Lighthouse
# LH port : 30062
def make_master_rules():
    LH_port = 30062
    # get existing rules
    security_rules = list(network_client.security_rules.list(
        resource_group,
        master_basename
    ))

    # find lowest existing priorioty
    low_prio = 0
    for s in security_rules:
        if s.priority > low_prio and s.direction == 'Inbound':
            low_prio = s.priority

    rule_name = 'px-port-LH'
    prio = low_prio + 1
    print("Adding LH security rule with port : ", LH_port, rule_name)
    async_security_rule = network_client.security_rules.create_or_update(
        resource_group,
        master_basename,
        rule_name,
        {
            'access': SecurityRuleAccess.allow,
            'description': 'Portworx Lighthouse security rule',
            'destination_address_prefix': '*',
            'destination_port_range': LH_port,
            'direction': SecurityRuleDirection.inbound,
            'priority': prio,
            'protocol': SecurityRuleProtocol.tcp,
            'source_address_prefix': '0.0.0.0/0',
            'source_port_range': LH_port
        }
    )
    async_security_rule.wait()

###################
#
#    main
#
##################


check_env()
subscription_id = os.environ.get('ARM_SUBSCRIPTION_ID')
credentials = ServicePrincipalCredentials(
    client_id=os.environ['ARM_CLIENT_ID'],
    secret=os.environ['ARM_CLIENT_SECRET'],
    tenant=os.environ['ARM_TENANT_ID']
)


cluster = os.getenv("CLUSTER")
num_vols = int(os.environ['ARM_NUM_VOLS'])
vol_size = int(os.environ['ARM_VOL_SIZE'])
region = os.environ['ARM_REGION']

resource_client = ResourceManagementClient(credentials, subscription_id)
compute_client = ComputeManagementClient(credentials, subscription_id)
storage_client = StorageManagementClient(credentials, subscription_id)
network_client = NetworkManagementClient(credentials, subscription_id)

resource_group = "tectonic-cluster-" + cluster
worker_basename = cluster + "-worker"
master_basename = cluster + "-master"

wvms = []
print("VMs for %s = " % (worker_basename))
for vm in get_vms(resource_group, worker_basename):
    print("    vm : ", vm)
    wvms.append(vm)

mvms = []
print("VMs for %s = " % (master_basename))
for vm in get_vms(resource_group, master_basename):
    print("    vm : ", vm)
    mvms.append(vm)

# Find worker Storage Acct
storage_acct = get_storage_acct(resource_group)
# print("Storage Acct = ", storage_acct)

for vm in wvms:
    attach_data_disk(resource_group, vm, region,
                     num_vols, vol_size, storage_acct)

# Worker network security group
wnsg = network_client.network_security_groups.get(
    resource_group, worker_basename)

# Get the worker subnet
wsubnet = network_client.subnets.get(
    resource_group,
    cluster,
    cluster + "_worker_subnet"
)

make_worker_rules(wsubnet)

# Master network security group
mnsg = network_client.network_security_groups.get(
    resource_group, master_basename)

make_master_rules()
