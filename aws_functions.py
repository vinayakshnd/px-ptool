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


def gen_aws_json(user_prefix, inst_px):
    """
    Function to generate output json as well as install portworx on each VM created with prefix defined by user_prefix
    :param user_prefix: string
    :return: None
    """
    tf_out = json.loads(subprocess.check_output('terraform output -no-color -json -state output/aws_{}.tfstate'
                                                .format(user_prefix), shell=True))
    pub_ip_list = tf_out['public_ips']['value']
    admuser = tf_out['admuser']['value']
    admpass = tf_out['admpassword']['value']
    private_ip_list = tf_out['private_ips']['value']
    json_out = []
    count = 0
    for public_ip in pub_ip_list:
        docker_disk = '/dev/xvdg'
        other_disks = []
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(public_ip, username=admuser, password=admpass)
        stdin, stdout, stderr = ssh.exec_command("lsblk")
        outlist = stdout.readlines()
        for l in outlist:
             if l.endswith('disk \n') and l.split()[0] not in ['xvda', 'xvdcz', 'xvdg']:
                other_disks.append("/dev/{}".format(l.split()[0]))
        instance_details = {"User": admuser,
                        "Passwd": admpass,
                        "PublicIpAddress": public_ip,
                        "PrivateIpAddress": private_ip_list[count],
                        "Port": "22",
                        "DockerDisk": docker_disk,
                        "Disks": other_disks}
        json_out.append(instance_details)
        count = count + 1
        if inst_px:
            px_installed, px_msg = install_px(public_ip, admuser, admpass)
            if px_installed:
                print "INFO : Portworx installed successfully on {}".format(public_ip)
            else:
                print "ERROR : Portworx installation failed on {} with following error message: {}". \
                    format(public_ip, px_msg)
    with open('output/aws_{}_output.json'.format(user_prefix), mode='w') as outfile:
        outfile.write(json.dumps(json_out, indent=4))
    print "========================================================"
    print " Output JSON is at output/aws_{}_output.json".format(user_prefix)
    print "========================================================"


if __name__ == '__main__':
    gen_aws_json(sys.argv[1], True)