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

echo "192.168.2.42 puppet" >> /etc/hosts

# dev mode
if [ -n "${DEV+set}" ]
then

  cat << EOF > /root/Makefile
all: run

run:
	puppet agent --server puppet \\
		--waitforcert 60 --onetime --verbose --no-daemonize \\
		--no-usecacheonfailure --no-splay --show_diff

clean:
	rm -rf /var/lib/puppet/*
	rm -rf /var/cache/puppet/*
EOF

  systemctl disable puppet-agent
fi
