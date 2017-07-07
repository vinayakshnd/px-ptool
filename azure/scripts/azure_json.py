import yaml
import json

json_out = []
yaml_file = 'azure/tfshow.yaml'
out_file = 'azure_output.json'

with open('azure/terraform.tfvars', mode='r') as f:
    admincfg = f.readlines()
username = ''
password = ''
for l in admincfg:
    if l.startswith('vm_admin_user'):
         username = l.split('=')[1].strip().replace('"','')
    if l.startswith('vm_admin_password'):
         password = l.split('=')[1].strip().replace('"','')

with open(yaml_file, mode='r') as f:
    ycfg = yaml.load(f)

for k in ycfg.keys():
    if k.startswith('azurerm_public_ip'):
        host_index = k.split(".")[-1]
        inst_details = {"User": username,
                        "PublicIpAddress": ycfg[k]['ip_address'],
                        "Passwd": password,
                        "Port": 22}
        json_out.append(inst_details)

with open(out_file, mode='w') as of:
    of.write(json.dumps(json_out, indent=4))