import sys
import requests
import time
import json

"""
Script to attach / detach volumes from droplets because
terraform makes it very painful to attach / detach volumes with droplets
"""

action = sys.argv[1]
user_prefix = sys.argv[2]
do_token = ''

with open ('digitalocean/creds.tfvars', mode='r') as cf:
    cred_cfg = cf.readlines()

for l in cred_cfg:
    if l.startswith('do_token'):
        do_token = l.split('=')[1].strip().replace('"','')

with open('output/digitalocean_{}_terraform.tfvars'.format(user_prefix), mode='r') as f:
    ycfg = f.readlines()
do_region = ''
private_key = ''
for l in ycfg:
    if l.startswith('px_region'):
        do_region = l.split('=')[1].strip().replace('"','')

    if l.startswith('private_key_file'):
        private_key = l.split('=')[1].strip().replace('"','')

auth_header = {'Authorization' : 'Bearer {}'.format(do_token)}
resp = requests.get('https://api.digitalocean.com/v2/volumes', headers=auth_header)
vol_dict = {}
print "INFO : Getting all Volumes"
for v in resp.json()['volumes']:
    if v['name'].startswith('do-{}-'.format(user_prefix)):
        vol_dict[v['name']] = v['id']

resp = requests.get('https://api.digitalocean.com/v2/droplets', headers=auth_header)
drop_dict = {}
print "INFO : Getting all Droplets"
for d in resp.json()['droplets']:
    if d['name'].startswith('px-{}-node-'.format(user_prefix)):
        drop_dict[d['name']] = d['id']
#
# If action is attach then generate output json
#
json_out = []
if action == 'attach':
    for d in resp.json()['droplets']:
        if d['name'].startswith('px-{}-node'.format(user_prefix)):
            droplet_details = {"User": "root",
                               "PublicIpAddress": d['networks']['v4'][0]['ip_address'],
                               "Passwd": private_key,
                               "Port": 22}
            json_out.append(droplet_details)
    with open('output/digitalocean_{}_output.json'.format(user_prefix), mode='w') as f:
        f.write(json.dumps(json_out, indent=4))


for droplet in drop_dict.keys():
    drop_index = droplet.split('-')[-1]
    for vol in vol_dict.keys():
        if vol.startswith('do-{}-'.format(user_prefix)) and vol.endswith('-{}'.format(drop_index)):
            print "INFO : {}ing volume {} to droplet {}".format(action, vol, droplet)
            do_url = 'https://api.digitalocean.com/v2/volumes/{}/actions'.format(vol_dict[vol])
            payload = { "type": action, "droplet_id": drop_dict[droplet], "region": do_region}
            post_header = {'Content-Type': 'application/json', 'Authorization': 'Bearer {}'.format(do_token)}
            resp = requests.post(do_url, headers=post_header, params=payload)
            time.sleep(2)



