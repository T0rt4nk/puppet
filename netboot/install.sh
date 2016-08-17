#!/usr/bin/env sh
set -x

BASE_URL="http://192.168.2.42:5050"
DEV=${DEV:-0}


# add ssh keys to user max
keys="/home/max/.ssh/authorized_keys"
sudo -u max mkdir -p "$(dirname $keys)"
sudo -u max wget -O "$keys" "$BASE_URL/id_rsa.pub"
sudo -u max chmod 600 "$keys"


# remove password for max
sed -i 's/max:[^:]*\(.*\)/max:*\1/' /etc/shadow


# add max to sudoers without password prompt
cat << EOF >> /etc/sudoers

max ALL=(ALL) NOPASSWD:ALL
EOF


# add docker resolver to resolv.conf
cat << EOF > /etc/resolv.conf
nameserver 172.17.0.1
nameserver 192.168.122.1
EOF

# prevent dhclient from overriding resolv.conf
cat << EOF > /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate
#!/bin/sh
make_resolv_conf() {
    :
}
EOF
chmod +x /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate


apt-get install -y puppet ssh

# dev mode
if [[ "$DEV" -e 1 ]]
then
    echo "dev mode"

fi
