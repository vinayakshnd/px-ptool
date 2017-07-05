import sys
import requests
import yaml
import time
import json

"""
Script to attach / detach volumes from droplets because
terraform makes it very painful to attach / detach volumes with droplets
"""

action = sys.argv[1]
with open('config.yaml', mode='r') as f:
    ycfg = yaml.load(f)

do_token = ycfg['digitalocean']['do_token']
do_region = ycfg['digitalocean']['do-region']
prefix = ycfg['digitalocean']['user_prefix']

auth_header = {'Authorization' : 'Bearer {}'.format(do_token)}
resp = requests.get('https://api.digitalocean.com/v2/volumes', headers=auth_header)
vol_dict = {}
print "INFO : Getting all Volumes"
for v in resp.json()['volumes']:
    vol_dict[v['name']] = v['id']

resp = requests.get('https://api.digitalocean.com/v2/droplets', headers=auth_header)
drop_dict = {}
print "INFO : Getting all Droplets"
for d in resp.json()['droplets']:
    drop_dict[d['name']] = d['id']
#
# If action is attach then generate output json
#
json_out = []
if action == 'attach':
    for d in resp.json()['droplets']:
        droplet_details = {"User": "root",
                           "PublicIpAddress": d['networks']['v4'][0]['ip_address'],
                           "Passwd": "use-private-key",
                           "Port": 22}
        json_out.append(droplet_details)
    with open('digitalocean_output.json', mode='w') as f:
        f.write(json.dumps(json_out, indent=4))


for droplet in drop_dict.keys():
    drop_index = droplet.split('-')[-1].replace('node', '')
    for vol in vol_dict.keys():
        if vol.startswith('do-vol-{}-{}'.format(prefix, drop_index)):
            print "INFO : {}ing volume {} to droplet {}".format(action, vol, droplet)
            do_url = 'https://api.digitalocean.com/v2/volumes/{}/actions'.format(vol_dict[vol])
            payload = { "type": action, "droplet_id": drop_dict[droplet], "region": do_region}
            post_header = {'Content-Type': 'application/json', 'Authorization': 'Bearer {}'.format(do_token)}
            resp = requests.post(do_url, headers=post_header, params=payload)
            time.sleep(2)



