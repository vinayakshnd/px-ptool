import sys
import paramiko
import time
import json

def install_px(pubip, usr, passwd):
    """
    This function installs portworx enterprise on a VM where install script is already provisioned at /tmp
    :param pubip: public IP of the instance
    :param usr: Admin user for the instance
    :param passwd: password for the instance
    :return: Boolean, Status message (Success in case of successful install and error message in case of failure
    """
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(pubip, username=usr, password=passwd)
    stdin, stdout, stderr = ssh.exec_command("sudo /tmp/install_px.sh")
    outlist = stdout.readlines()
    errlist = stderr.readlines()
    cmdout = ''
    print "INFO : stdout {} stderr {}".format(outlist, errlist)
    for n in range(10):
        time.sleep(70)
        cmdout = px_healthcheck(pubip, usr, passwd)
        if cmdout:
            try:
                myjson = json.loads(cmdout)
                if myjson['status'] == 'STATUS_OK':
                    return True, 'Success'
            except ValueError:
                print "INFO : PX Health Check on {}, Attempt {} of 10".format(pubip, n)
    return False, cmdout


def px_healthcheck(pubip, usr, passwd):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(pubip, username=usr, password=passwd)
    stdin, stdout, stderr = ssh.exec_command("sudo /opt/pwx/bin/pxctl --json status")
    outlist = stdout.readlines()
    errlist = stderr.readlines()
    print "INFO : stdout {} stderr {}".format(outlist, errlist)
    return ''.join(outlist)

if __name__ == '__main__':
    outlist = px_healthcheck(sys.argv[1], sys.argv[2], sys.argv[3])
    myjson = json.loads(''.join(outlist))
    print "INFO : Status is {}".format(myjson['status'])