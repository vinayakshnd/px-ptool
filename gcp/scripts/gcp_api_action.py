from googleapiclient.discovery import build
from oauth2client.client import GoogleCredentials
import sys
import json
import yaml
import time

#with open('config.yaml', mode='r') as admincfg:
#    cfg = yaml.load(admincfg)

action = sys.argv[1]

with open('gcp/terraform.tfvars', mode='r') as f:
    cfg = f.readlines()

service_key = ''
project = ''
zone = ''
user_prefix = ''
private_key = ''

for l in cfg:
    if l.startswith('credentials_file_path'):
        service_key = l.split('=')[1].strip().replace('"','')
    if l.startswith('project'):
        project = l.split('=')[1].strip().replace('"','')
    if l.startswith('px_region_zone'):
        zone = l.split('=')[1].strip().replace('"','')
    if l.startswith('user_prefix'):
        user_prefix = l.split('=')[1].strip().replace('"','')
    if l.startswith('private_key_path'):
        private_key = l.split('=')[1].strip().replace('"','')

credentials = GoogleCredentials.from_stream('gcp/' + service_key)
compute = build('compute', 'v1', credentials=credentials)

#
# List instances
#
result = compute.instances().list(project=project, zone=zone).execute()

inst_dict = {}
json_out = []
print "INFO : Getting all instances"
for i in result['items']:
    inst_dict[i['name']] = i['id']
    if action == 'attach':
        inst_details = {"User": "root",
                           "PublicIpAddress": i['networkInterfaces'][0]['accessConfigs'][0]['natIP'],
                           "Passwd": private_key,
                           "Port": 22}
        json_out.append(inst_details)
        with open('gcp_output.json', mode='w') as f:
            f.write(json.dumps(json_out, indent=4))



result = compute.disks().list(project=project, zone=zone).execute()
disk_dict = {}
print "INFO : Getting all disks"
for d in result['items']:
    disk_dict[d['name']] = d['selfLink']

for inst in inst_dict.keys():
    inst_index = inst.split('-')[-1]
    for disk in disk_dict.keys():
        if disk.startswith('px-gcp-vol-{}-{}'.format(user_prefix, inst_index)):
            if action == 'attach':
                print "INFO : attaching disk {} to instance {}".format(disk, inst)
                body = {"type": "PERSISTENT", "mode": "READ_WRITE", "source": disk_dict[disk],
                        "deviceName": disk, "boot": False, "autoDelete": False, "interface": "SCSI"}
                res = compute.instances().attachDisk(project=project, zone=zone,
                                                     instance=inst, body=body).execute()
            if action == 'detach':
                print "INFO : detaching disk {} from instance {}".format(disk, inst)
                res = compute.instances().detachDisk(project=project, zone=zone, instance=inst,
                                                     deviceName=disk).execute()
#
# Calling a small sleep to ensure last volume is deleted before we call destruction
if action == 'detach':
    time.sleep(5)