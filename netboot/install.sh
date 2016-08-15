#!/usr/bin/env sh
set -x

BASE_URL="http://192.168.2.42:5050"
USER="max"
USER_HOME="/home/max"

ssh_dir="$USER_HOME/.ssh"

sudo -u max mkdir "$ssh_dir"
sudo -u max wget -O "$ssh_dir/authorized_keys" "$BASE_URL/id_rsa.pub"
sudo -u max chmod 600 "$ssh_dir/authorized_keys"

apt-get install -y ssh
echo "max ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# remove password for max
sed -i 's/max:[^:]*\(.*\)/max:*\1/' /etc/shadow

apt-get install -y puppet
