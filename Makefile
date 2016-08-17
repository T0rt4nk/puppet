.PHONY: clean build run

netboot = "$(PWD)/netboot"
bin = /tmp/bin
iso = /tmp/ipxe.iso

debian_url = "http://mirror.rackspace.com/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64"

ensure_bin:
	mkdir -p $(bin)

build: ensure_bin
	docker run -v "$(bin):/tmp/ipxe/src/bin" ipxe

build.script: ensure_bin
	docker run -v "$(bin):/tmp/ipxe/src/bin" \
		-v "$(PWD)/scripts:/tmp/ipxe/src/scripts" ipxe \
		bin/ipxe.iso EMBED=scripts/script.ipxe

img.ipxe:
	docker build -f dockerfile_ipxe -t ipxe .

img.server:
	docker build -f dockerfile_server -t ipxe_server .

img.puppet:
	docker build -f dockerfile_puppet -t puppet .

img: img.ipxe img.server

run.virsh: clean.virsh clean.volumes
	sudo rm -f $(iso)
	cp $(bin)/ipxe.iso $(iso)
	virt-install --name ipxe --memory 1024 --virt-type kvm \
		--cdrom $(iso) --network network=default \
        --disk size=10 --noautoconsole

run.server:
	wget -N -P $(netboot) $(debian_url)/linux
	wget -N -P $(netboot) $(debian_url)/initrd.gz
	cp "$(HOME)/.ssh/id_rsa.pub" $(CURDIR)/netboot
	docker run -v "$(netboot):/mnt/netboot" -p 5050:80 ipxe_server

run.puppet:
	docker run -h puppet -v "$(PWD)/puppet:/home/puppet/.puppetlabs" --rm puppet

clean:
	rm -rf "$(CURDIR)/bin/*"

clean.virsh:
	virsh list | awk '$$2 ~ /ipxe/ {system("virsh destroy " $$2)}'
	virsh list --all | awk '$$2 ~ /ipxe/ {system("virsh undefine " $$2)}'

clean.puppet:
	rm -rf puppet/etc/code
	rm -rf puppet/etc/puppet/ssl
	rm -rf puppet/opt
	rm -rf puppet/var

ssh:
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i $(HOME)/.ssh/id_rsa tortank.debian.docker

clean.volumes:
	virsh vol-list default | awk \
		'NR > 2 && NF > 0 {system("xargs virsh vol-delete --pool default " $$1)}'
