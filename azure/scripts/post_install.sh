#!/bin/bash
set -e

MY_UUID=$1;
MY_PASSWD=$2;
OS_NAME=$(grep "^ID=" /etc/os-release | cut -d"=" -f2 | tr -cd '[:alnum:]')

# Below is a dirty little hack to allow passwordless sudo using password
cat <<EOF > /tmp/deleteme.sh
echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/waagent
EOF
chmod 755 /tmp/deleteme.sh
echo $MY_PASSWD | sudo -S /tmp/deleteme.sh


if [[ "${OS_NAME}" == "centos" ]]; then
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
    echo "Defaults:${USER}" '!requiretty' | sudo tee -a /etc/sudoers
fi

# Adding /usr/sbin to $PATH

export PATH=${PATH}:/usr/sbin/

PRIV_IP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/privateIpAddress?api-version=2017-04-02&format=text")
NET_INTF=$(ip a | grep ${PRIV_IP} | awk '{print $NF}')
#
# Install Docker directly
curl -fsSL https://get.docker.com/ | sudo sh

sudo mount --make-shared /
if [[ "${OS_NAME}" != "centos" ]]; then
    sudo mount --make-shared /mnt
fi

if [[ "${OS_NAME}" != "ubuntu" ]]; then
    sudo service docker start
fi

# Install PX enterprise
#
cat <<EOF > /tmp/install_px.sh
#!/bin/bash
echo "========= Starting PX Enterprise ==============";
sudo docker run --name px-enterprise -d --net=host --privileged=true --restart=always -v /mnt:/mnt:shared \
-v /var/cores:/var/cores -v /run/docker/plugins:/run/docker/plugins -v /lib/modules:/lib/modules \
-v /var/lib/osd:/var/lib/osd:shared -v /dev:/dev -v /usr/src:/usr/src -v /etc/pwx:/etc/pwx \
-v /opt/pwx/bin:/export_bin:shared -v /var/run/docker.sock:/var/run/docker.sock \
portworx/px-enterprise:1.2.9 \
-k etcd://etcd-us-east-1b.portworx.com:4001,etcd://etcd-us-east-1c.portworx.com:4001,etcd://etcd-us-east-1d.portworx.com:4001 \
-a -m ${NET_INTF} -d ${NET_INTF} -c ${MY_UUID}
EOF
chmod 755 /tmp/install_px.sh