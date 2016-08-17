.PHONY: clean build run

all: build

kernel = "$(PWD)/bin/ipxe.lkrn"
kernel.virsh = "/tmp/ipxe.lkrn"

netboot = "$(PWD)/netboot"
bin = $(CURDIR)/bin
iso = /tmp/ipxe.iso

debian_url = "http://mirror.rackspace.com/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64"

build:
	docker run -v "$(PWD)/bin:/tmp/ipxe/src/bin" ipxe

build.script:
	docker run -v "$(PWD)/bin:/tmp/ipxe/src/bin" \
		-v "$(PWD)/scripts:/tmp/ipxe/src/scripts" ipxe \
		bin/ipxe.iso EMBED=scripts/script.ipxe

run:
	qemu-system-x86_64 -enable-kvm -m 1G -kernel $(kernel)


img.ipxe:
	docker build -f dockerfile_ipxe -t ipxe .

img.server:
	docker build -f dockerfile_server -t ipxe_server .

img: img.ipxe img.server

run.virsh: clean.virsh clean.volumes
	sudo rm -f $(iso)
	cp $(bin)/ipxe.iso $(iso)
	virt-install --name ipxe --memory 1024 --virt-type kvm \
		--cdrom $(iso) --network network=default \
        --disk size=10

run.server:
	wget -N -P $(netboot) $(debian_url)/linux
	wget -N -P $(netboot) $(debian_url)/initrd.gz
	cp "$(HOME)/.ssh/id_rsa.pub" $(CURDIR)/netboot
	docker run -v "$(netboot):/mnt/netboot" -p 5050:80 ipxe_server

clean:
	rm -rf "$(CURDIR)/bin/*"

clean.virsh:
	-virsh list | grep -q ipxe && virsh destroy ipxe
	-virsh list --all | grep -q ipxe && virsh undefine ipxe

cmd = "xargs virsh vol-delete --pool default "

clean.volumes:
	virsh vol-list default | awk 'NR > 2 && NF > 0 {system($(cmd) $$1)}'
