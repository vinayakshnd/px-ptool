#!/usr/bin/env bash
set -e
MYUSER=$1;
MYPASS=$2;
PUB_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
MY_UUID=$3;
# Generate UUID using cat /proc/sys/kernel/random/uuid

#
# Enable password based login
#
sed -i "s|PasswordAuthentication .*|PasswordAuthentication yes|g" /etc/ssh/sshd_config
service sshd restart
#
# Add admuser
useradd -p $(openssl passwd -1 ${MYPASS}) ${MYUSER}

#
# Add user to sudoers
#usermod -aG sudo ${MYUSER}

echo "Defaults:${MYUSER} !requiretty" >> /etc/sudoers
echo "${MYUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#
# Install docker
curl -fsSL https://get.docker.com/ | sh
service docker start

#
# Find interface which binds to external IP
NET_INTF=$(ip a | grep ${PUB_IP} | awk '{print $NF}')

#
# Install PX-Enterprise
cat<<EOF >/tmp/install_px.sh
docker run --name px-enterprise -d --net=host --privileged=true --restart=always -v /mnt:/mnt:shared \
-v /var/cores:/var/cores -v /run/docker/plugins:/run/docker/plugins -v /lib/modules:/lib/modules \
-v /var/lib/osd:/var/lib/osd:shared -v /dev:/dev -v /usr/src:/usr/src -v /etc/pwx:/etc/pwx \
-v /opt/pwx/bin:/export_bin:shared -v /var/run/docker.sock:/var/run/docker.sock \
portworx/px-enterprise:1.2.9 \
-k etcd://etcd-us-east-1b.portworx.com:4001,etcd://etcd-us-east-1c.portworx.com:4001,etcd://etcd-us-east-1d.portworx.com:4001 \
-a -m ${NET_INTF} -d ${NET_INTF} -c ${MY_UUID}
EOF
chmod 755 /tmp/install_px.sh