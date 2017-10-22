#!/bin/bash
set -e

MY_USER=$1;
MY_PASSWD=$2;
MY_UUID=$3;
PX_IMAGE=$4;
PUB_IP=$5;
PX_DOCKER_IMAGE=$6;
SSH_SVC=sshd
#
# Install ECS agent
#sudo yum install -y ecs-init
#sudo service docker start
sudo start ecs || true
#curl http://localhost:51678/v1/metadata

sed -i "s|PasswordAuthentication .*|PasswordAuthentication yes|g" /etc/ssh/sshd_config
service ${SSH_SVC} restart

#
# Add admuser
sudo useradd -p $(openssl passwd -1 ${MY_PASSWD}) ${MY_USER} || true

#
# Add entry in Sudoers
echo "${MY_USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
echo "Defaults:${MY_USER}" '!requiretty' | sudo tee -a /etc/sudoers


#
# Install Docker directly
curl -fsSL https://get.docker.com/ | sudo sh

#
# Create symlink to docker binary
if [ ! -f /bin/docker ]; then
        sudo ln -s /usr/bin/docker /bin/docker 
fi

sudo mount --make-shared / 

#if [[ "${OS_NAME}" == "centos" ]]; then
#    
    sudo systemctl enable docker
    sudo service docker start

    #
    #  Install FIO
    sudo yum -y install wget                                         
    sudo wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
    sudo rpm -Uvh --replacepkgs epel-release-7-10.noarch.rpm           
    sudo yum -y install fio 
   
#fi

# For ECS only
#sudo mount --make-shared /
#sudo sed -i.bak -e \
#        's:^\(\ \+\)"$unshare" -m -- nohup:\1"$unshare" -m --propagation shared -- nohup:' \
#         /etc/init.d/docker
sudo service docker restart

#
# Find interface which binds to external IP
NET_INTF=$(ip a | grep ${PUB_IP} | awk '{print $NF}')

cat<<EOF >/tmp/install_px.sh
[ ! "$(docker ps | grep px-enterprise)" ] && docker run --restart=always --name px-enterprise -d --net=host \
               --privileged=true                             \
               -v /run/docker/plugins:/run/docker/plugins    \
               -v /var/lib/osd:/var/lib/osd:shared           \
               -v /dev:/dev                                  \
               -v /etc/pwx:/etc/pwx                          \
               -v /opt/pwx/bin:/export_bin:shared            \
               -v /var/run/docker.sock:/var/run/docker.sock  \
               -v /var/cores:/var/cores                      \
               -v /usr/src:/usr/src                          \
               -v /mnt:/mnt:shared                           \
               ${PX_DOCKER_IMAGE} -daemon -k etcd://etcd-us-east-1b.portworx.com:4001,etcd://etcd-us-east-1c.portworx.com:4001,etcd://etcd-us-east-1d.portworx.com:4001 \
               -a -m ${NET_INTF} -d ${NET_INTF} -c ${MY_UUID}
EOF
chmod 755 /tmp/install_px.sh