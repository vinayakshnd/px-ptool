import requests
import time
import json
import subprocess
import paramiko
from px_functions import install_px

def get_tf_out(user_prefix, prop):
    if prop == 'do_token':
        with open('digitalocean/creds.tfvars', mode='r') as cf:
            cred_cfg = cf.readlines()
        do_token = ''
        for l in cred_cfg:
            if l.startswith('do_token'):
                do_token = l.split('=')[1].strip().replace('"', '')
        return do_token
    tf_output = subprocess.check_output('terraform output -state output/digitalocean_{}.tfstate'.format(user_prefix),
                                        shell=True)
    for l in tf_output.splitlines():
        if l.startswith(prop):
            prop = l.split('=')[1].strip().replace('"', '')
    return prop


def do_output_json(drop_objs, user_prefix, inst_px):
    json_out = []
    private_ip = ''
    public_ip = ''
    adm_user = get_tf_out(user_prefix, 'vm_admin_user')
    adm_pass = get_tf_out(user_prefix, 'vm_admin_password')
    for d in drop_objs:
        if d['name'].startswith('px-{}-node-'.format(user_prefix)):
            docker_disk = ''
            other_disks = []
            for n in d['networks']['v4']:
                if n['type'] == 'private':
                    private_ip = n['ip_address']
                if n['type'] == 'public':
                    public_ip = n['ip_address']
            if public_ip != '':
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(public_ip, username=adm_user, password=adm_pass)
                stdin, stdout, stderr = ssh.exec_command("ls -l /dev/disk/by-id/*")
                outlist = stdout.readlines()
                for l in outlist:
                    if 'docker' in l.split(' ')[-3].strip().split('_')[-1]:
                        docker_disk = "/dev/{}".format(l.split(' ')[-1].strip().split('/')[-1])
                    else:
                        other_disks.append("/dev/{}".format(l.split(' ')[-1].strip().split('/')[-1]))
                drop_details = {"User": adm_user,
                                "Passwd": adm_pass,
                                "PublicIpAddress": public_ip,
                                "PrivateIpAddress": private_ip,
                                "Port": "22",
                                "DockerDisk": docker_disk,
                                "Disks": other_disks}
                json_out.append(drop_details)
                if inst_px is True:
                    px_installed, px_msg = install_px(public_ip, adm_user, adm_pass)
                    if px_installed:
                        print "INFO : Portworx installed successfully on {}".format(public_ip)
                    else:
                        print "ERROR : Portworx installation failed on {} with following error message: {}".\
                            format(public_ip, px_msg)

    with open('output/digitalocean_{}_output.json'.format(user_prefix), mode='w') as outfile:
        outfile.write(json.dumps(json_out, indent=4))
    print "========================================================"
    print " Output JSON is at output/digitalocean_{}_output.json".format(user_prefix)
    print "========================================================"


def do_api_action(action, user_prefix, inst_px):
    do_token = get_tf_out(user_prefix, 'do_token')
    do_region = get_tf_out(user_prefix, 'do_region')
    auth_header = {'Authorization': 'Bearer {}'.format(do_token)}
    resp = requests.get('https://api.digitalocean.com/v2/volumes', headers=auth_header)
    vol_dict = {}
    print "INFO : Getting all Volumes"
    for v in resp.json()['volumes']:
        if v['name'].startswith('do-{}-'.format(user_prefix)):
            vol_dict[v['name']] = v['id']
    resp = requests.get('https://api.digitalocean.com/v2/droplets', headers=auth_header)
    drop_dict = {}
    print "INFO : Getting all Droplets"
    drop_objs = resp.json()['droplets']
    for d in drop_objs:
        if d['name'].startswith('px-{}-node-'.format(user_prefix)):
            drop_dict[d['name']] = d['id']

    for droplet in sorted(drop_dict):
        drop_index = droplet.split('-')[-1]
        for vol in sorted(vol_dict):
            if vol.startswith('do-{}-'.format(user_prefix)) and vol.endswith('-{}'.format(drop_index)):
                print "INFO : {}ing volume {} to droplet {}".format(action, vol, droplet)
                do_url = 'https://api.digitalocean.com/v2/volumes/{}/actions'.format(vol_dict[vol])
                payload = {"type": action, "droplet_id": drop_dict[droplet], "region": do_region}
                post_header = {'Content-Type': 'application/json', 'Authorization': 'Bearer {}'.format(do_token)}
                resp = requests.post(do_url, headers=post_header, params=payload)
                print "INFO : Status for {}ing volume {} to {} is {}".format(action, vol, droplet, resp.status_code)
                time.sleep(2)
    if action == 'attach':
        do_output_json(drop_objs, user_prefix, inst_px)
if __name__ == '__main__':
    do_api_action('attach', 'gendry', True)
