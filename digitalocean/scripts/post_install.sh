#!/usr/bin/env bash

MYUSER=$1;
MYPASS=$2;
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