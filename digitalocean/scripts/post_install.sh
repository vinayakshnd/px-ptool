#!/usr/bin/env bash

MYUSER='admuser';
MYPASS='s3cret';
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
usermod -aG sudo ${MYUSER}

echo "${MYUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers