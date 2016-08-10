.PHONY: clean build run

all: build

kernel = "$(PWD)/bin/ipxe.lkrn"
kernel.virsh = "/tmp/ipxe.lkrn"

iso = "$(HOME)/Downloads/archlinux-2016.08.01-dual.iso"
mountpoint = "$(PWD)/iso"

clean:
	rm -rf "$(CURDIR)/bin/*"

build:
	docker run -v "$(PWD)/bin:/tmp/ipxe/src/bin" ipxe

build.script:
	docker run -v "$(PWD)/bin:/tmp/ipxe/src/bin" \
		-v "$(PWD)/scripts:/tmp/ipxe/src/scripts" ipxe \
		bin/ipxe.lkrn EMBED=scripts/script.ipxe

run:
	qemu-system-x86_64 -enable-kvm -m 1G -kernel $(kernel)


img.ipxe:
	docker build -f dockerfile_ipxe -t ipxe .

img.server:
	docker build -f dockerfile_server -t ipxe_server .

img: img.ipxe img.server

run.virsh:
	test -s /tmp/ipxe.lkrn && sudo rm $(kernel.virsh)
	cp $(kernel) $(kernel.virsh)
	virt-install --name ipxe --memory 1024 --virt-type kvm --nodisks \
		--boot kernel="/tmp/ipxe.lkrn" --network network=default

run.server:
	mount |grep -q $(iso) || sudo mount -o loop,ro $(iso) $(mountpoint)
	docker run -v "$(mountpoint):/mnt/iso" -p 5000:80 ipxe_server

clean.virsh:
	virsh destroy ipxe
	virsh undefine ipxe
