#!/usr/bin/env sh
set -x

BASE_URL="http://192.168.2.42:5050"
DEV=${DEV:-0}

# install required packages
apt-get install -y puppet ssh curl

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

# create a script and a systemd entry to register tortank into dnsdock
cat << EOF > /usr/local/bin/dnsdock
#!/bin/sh

# Get current IP address
IP=\$(/sbin/ip -4 -o addr show dev eth0| awk '{split(\$4,a,"/");print a[1]}')

# Try to remove tortank entry
curl -s http://dnsdock.docker/services/tortank -X DELETE > /dev/null

# Update the entry with the actualized IP address
curl http://dnsdock.docker/services/tortank -X PUT --data-ascii \
  '{"name": "tortank", "image": "debian", "ip": "'\$IP'", "ttl": 30}'

EOF
chmod +x /usr/local/bin/dnsdock

cat << EOF > /etc/systemd/system/dnsdock.service
[Unit]
Description=Register to docker DNS service
After=network.target
Requires=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dnsdock

[Install]
WantedBy=multi-user.target
EOF

systemctl enable dnsdock


# dev mode
if [[ "$DEV" -e 1 ]]
then
    echo "dev mode"

fi
