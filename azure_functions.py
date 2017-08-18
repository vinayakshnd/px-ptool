import json
import sys
import subprocess
import paramiko
from px_functions import install_px

#
# Terraform will create VM, attach disks and also install docker via provisioning
# All that we need to do is
# 1. Generate output JSON
# 2. Run PX installation script and check health of px installation


def gen_azure_json(user_prefix):
    """
    Function to generate output json as well as install portworx on each VM created with prefix defined by user_prefix
    :param user_prefix: string
    :return: None
    """
    CURL_PRIVATE_IP='curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-04-02&format=text"'
    tf_out = json.loads(subprocess.check_output('terraform output -no-color -json -state output/azure_{}.tfstate'
                                                .format(user_prefix), shell=True))
    pub_ip_list = tf_out['public_ips']['value']
    admuser = tf_out['admuser']['value']
    admpass = tf_out['admpassword']['value']
    json_out = []
    for public_ip in pub_ip_list:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(public_ip, username=admuser, password=admpass)
        stdin, stdout, stderr = ssh.exec_command(CURL_PRIVATE_IP)
        private_ip = stdout.readlines()
        ssh.connect(public_ip, username=admuser, password=admpass)
        stdin, stdout, stderr = ssh.exec_command("lsblk")
        outlist = stdout.readlines()
        docker_disk = 'sdc'
        other_disks = []
        for l in outlist:
            if l.endswith('disk \n') and l.split()[0] not in ['sda', 'sdb', 'sdc']:
                other_disks.append(l.split()[0])
        drop_details = {"User": admuser,
                        "Passwd": admpass,
                        "PublicIpAddress": public_ip,
                        "PrivateIpAddress": private_ip[0],
                        "Port": "22",
                        "DockerDisk": docker_disk,
                        "Disks": other_disks}
        json_out.append(drop_details)
        px_installed, px_msg = install_px(public_ip, admuser, admpass)
        if px_installed:
            print "INFO : Portworx installed successfully on {}".format(public_ip)
        else:
            print "ERROR : Portworx installation failed on {} with following error message: {}". \
                format(public_ip, px_msg)
    with open('output/azure_{}_output.json'.format(user_prefix), mode='w') as outfile:
        outfile.write(json.dumps(json_out, indent=4))
    print "========================================================"
    print " Output JSON is at output/azure_{}_output.json".format(user_prefix)
    print "========================================================"


if __name__ == '__main__':
    gen_azure_json(sys.argv[1])