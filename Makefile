.PHONY: clean build run

all: build

kernel = "$(PWD)/bin/ipxe.lkrn"
kernel.virsh = "/tmp/ipxe.lkrn"

clean:
	rm -rf "$(CURDIR)/bin/*"

build: 
	docker run -v "$(PWD)/bin:/tmp/ipxe/src/bin" ipxe

run:
	qemu-system-x86_64 -enable-kvm -m 1G -kernel $(kernel)

run.virsh:
	rsync --chown max:max $(kernel) $(kernel.virsh)
	virt-install --name ipxe --memory 1024 --virt-type kvm --nodisks \
		--boot kernel="/tmp/ipxe.lkrn" --network network=default

clean.virsh:
	virsh destroy ipxe
	virsh undefine ipxe
