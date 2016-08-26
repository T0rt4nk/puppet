#!/usr/bin/env sh
set -x

BASE_URL="http://192.168.2.42:5050"

while getopts "d" OPTION
do
  case $OPTION in
    d)
      DEV=
      ;;
  esac
done

# setup source.list to something more compliant

cat << EOF > /etc/apt/sources.list
deb http://httpredir.debian.org/debian jessie main non-free contrib
deb-src http://httpredir.debian.org/debian jessie main non-free contrib

deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free

deb http://httpredir.debian.org/debian jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free


deb http://httpredir.debian.org/debian sid main contrib non-free
deb-src http://httpredir.debian.org/debian sid main contrib non-free

deb http://httpredir.debian.org/debian experimental main contrib non-free
deb-src http://httpredir.debian.org/debian experimental main contrib non-free
EOF

cat << EOF > /etc/apt/preferences.d/debian-repos.pref
Package: *
Pin: release a=stable
Pin-Priority: 550

Package: *
Pin: release a=unstable
Pin-Priority: 450
EOF

# install required packages
apt-get update
apt-get install -y ssh curl make
apt-get install -t sid -y puppet-agent

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
curl -s http://dnsdock.docker/services/tortank -X PUT --data-ascii \
  '{"name": "tortank", "image": "debian", "ip": "'\$IP'", "ttl": 30}'

EOF
chmod +x /usr/local/bin/dnsdock

cat << EOF > /etc/systemd/system/dnsdev.service
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

systemctl enable dnsdev


# dev mode
if [ -n "${DEV+set}" ]
then

  cat << EOF > /root/Makefile
all: run

run:
	puppet agent --server puppet.docker --certname tortank.docker \\
		--waitforcert 60 --onetime --verbose --no-daemonize \\
		--no-usecacheonfailure --no-splay --show_diff

clean:
	rm -rf /var/lib/puppet/*
	rm -rf /var/cache/puppet/*
EOF

  systemctl disable puppet-agent
fi
