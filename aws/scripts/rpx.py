#!/usr/bin/env python
#
# ready4px: Take a cluster that has been deployed through Tectonic,
#           and make it ready to run/deploy Portworx
#
# Inputs:
#        Environment:
#              AWS_CLUSTER :   Corresponds to CLUSTER from Tectonic
#              AWS_SECRET_ACCESS_KEY, AWS_ACCESS_KEY_ID, 
#              AWS_DEFAULT_REGION : Amazon credentials and region
#              AWS_VOL_TYPE:  standard'|'io1'|'gp2'|'sc1'|'st1'
#              AWS_VOL_SIZE:  in GBs
#              AWS_VOL_NAMES:  /dev names for attach.  Start with "/dev/xvdd", ...
#
# Assumptions:
#      The target cluster has a set of instances derived from two
#      auto-scaling groups called  $AWS_CLUSTER-masters and $AWS_CLUSTER-workers
#      This happens to be the structure for Tectonic.
#      This may apply to other targets.
#      

import os
import sys
import time
import boto3
from pprint import pprint
from botocore.exceptions import ClientError

# PX-ports, needed open between workers
pxports = [ 9001, 9002, 9003, 9010, 9012, 9014 ]
envars = [ "AWS_SECRET_ACCESS_KEY", "AWS_ACCESS_KEY_ID", "AWS_DEFAULT_REGION",
            "AWS_CLUSTER", "AWS_VOL_TYPE", "AWS_VOL_SIZE", "AWS_VOL_NAMES" ]


def check_prereqs():
    for e in envars:
       #  if not os.getenv(e): 
       if not e in os.environ:
           print ("FATAL: {} is not defined".format(e))
           sys.exit(-1)

#
# asg_to_iids:  Given an auto-scaling group name,  return the corresponding list of instanceIDs
#
def asg_to_iids(asgname):

    asclient = boto3.client('autoscaling')

    # Array of instance IDs
    iids = []

    asgs = asclient.describe_auto_scaling_groups(
        AutoScalingGroupNames=[
            asgname
        ]
    )
    
    for a in asgs['AutoScalingGroups']:
        for ids in a['Instances']:
            iids.append(ids['InstanceId'])
    
    return iids


def list_instances(grp, iids):
     for i in iids:
          print ('{} : {}'.format(grp,i))
        
def pxify_masters(ec2, master_sg):

    print ("px-ifying ", master_sg)
    msg = ec2.SecurityGroup(master_sg)
    try:
        msg.authorize_ingress( IpProtocol="tcp", CidrIp="0.0.0.0/0", FromPort=30062, ToPort=30062 )
    except ClientError as e:
        if e.response['Error']['Code'] == 'EntityAlreadyExists':
             print ("Object already exists")
        else:
             print ("Unexpected error: %s" % e)


#
# Add ports to the workers Security Group
#
def pxify_workers_sg (ec2, worker_sg, wvpc):

    print ("px-ifying security group", worker_sg)
    wsg = ec2.SecurityGroup(worker_sg)

    for p in pxports:
        try:
            wsg.authorize_ingress( IpPermissions=[{'FromPort': p, 'IpProtocol': 'tcp', 'ToPort': p,
                                   'UserIdGroupPairs' : [{'GroupId': worker_sg, 'VpcId' : wvpc}]}])
            print ("Added port {} to security_group {}".format(p, worker_sg))
        except ClientError as e:
            if e.response['Error']['Code'] == 'EntityAlreadyExists':
                 print ("Object already exists")
            else:
                 print ("Unexpected error: %s" % e)

def waitfor_vol (ec2r, volid):
    while True:
        if ec2r.Volume(volid).state == "available":
             return
        else:
             print ("          Waiting for ", volid)
             time.sleep(2)
#
# Add and attach volumes to the workers instances
#    
def pxify_workers_vols (ec2c, ec2r, workers):

    vol_size = os.getenv("AWS_VOL_SIZE")
    vol_type = os.getenv("AWS_VOL_TYPE")
    vol_names = os.environ.get("AWS_VOL_NAMES").split(" ")
    vol_region = os.getenv("AWS_DEFAULT_REGION")
     
    for w in workers:
        print ("Creating volumes for instance : ", w)
        az = ec2r.Instance(w).placement['AvailabilityZone']
        print ("     {} has az {}".format(w, az))
        # Count the number of disks per instance.  Make sure there aren't more than there should be
        # nblkdevs = len(ec2r.Instance(w).block_device_mappings)
        # print ("Instance {} has {} devices attached".format(w, nblkdevs))
        
        for name in vol_names:
            try:
               vol = ec2c.create_volume ( AvailabilityZone=az, Size=int(vol_size), VolumeType=vol_type)
               print ("     Created ", vol['VolumeId'])
               waitfor_vol (ec2r, vol['VolumeId'])
               try:
                   ec2r.Instance(w).attach_volume( Device=name, VolumeId=vol['VolumeId'])
                   print ("          Attached {} to {}".format(vol['VolumeId'], w))
               except ClientError as e:
                   print ("     Volume attach error: %s" % e)
               
            except ClientError as e:
               print ("     Volume create error: %s" % e)



if __name__ == "__main__":

    check_prereqs()

    masters_asg = '{}-{}'.format(os.getenv("AWS_CLUSTER"),"masters")
    workers_asg = '{}-{}'.format(os.getenv("AWS_CLUSTER"),"workers")
    
    masters = asg_to_iids(masters_asg)
    workers = asg_to_iids(workers_asg)
   
    if not masters or not workers:
        print("No instances listed for cluster : ", os.getenv("AWS_CLUSTER"))
        sys.exit(-1)

    ec2c = boto3.client('ec2')
    ec2r = boto3.resource('ec2')

    list_instances(masters_asg, masters)
    master_sg =  ec2r.Instance(masters[0]).security_groups[0]['GroupId']
    print ("Masters Security Group = ", master_sg)
    pxify_masters(ec2r, master_sg)
    
    list_instances(workers_asg, workers)
    worker_sg = ec2r.Instance(workers[0]).security_groups[0]['GroupId']
    print ("Workers Security Group = ", worker_sg)
    worker_vpc = ec2r.Instance(workers[0]).vpc_id
    pxify_workers_sg (ec2r, worker_sg, worker_vpc)

    pxify_workers_vols (ec2c, ec2r, workers)
