data = "$(PWD)/server/data"
bin = /tmp/bin
iso = /tmp/ipxe.iso

define puppet =
docker run -h puppet --rm \
	-v "$(PWD)/puppet/puppetlabs:/home/puppet/.puppetlabs" \
	-v "$(PWD)/puppet/tortank:/home/puppet/tortank" \
	-v "$(PWD)/puppet/hiera:/var/lib/hiera" \
	-ti puppet $(1)
endef


debian_url = "http://mirror.rackspace.com/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64"

all: ensure clean img build.ipxe run.virsh

ensure:
	@echo "In order to make this environment work, be sure to have ran"
	@echo "                                                           "
	@echo "                    => make run.server                     "
	@echo "                                                           "
	@echo "in an other shell                                          "
	@sudo echo "starting build..."

ssh:
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
		-i $(HOME)/.ssh/id_rsa tortank.debian.docker

build.ipxe:
	mkdir -p $(bin)
	docker run -v "$(bin):/tmp/ipxe/src/bin" \
		-v "$(PWD)/ipxe:/tmp/ipxe/src/data" ipxe \
		bin/ipxe.iso EMBED=data/script.ipxe

img.ipxe:
	docker build -t ipxe ./ipxe

img.server:
	docker build -t server ./server

img.puppet:
	docker build -t puppet ./puppet

img: img.server img.ipxe img.puppet

run.virsh: clean.virsh clean.volumes
	sudo rm -f $(iso)
	cp $(bin)/ipxe.iso $(iso)
	virt-install --name ipxe --memory 1024 --virt-type kvm \
		--cdrom $(iso) --network network=default \
        --disk size=10 --noautoconsole

run.server:
	wget -N -P $(data) $(debian_url)/linux
	wget -N -P $(data) $(debian_url)/initrd.gz
	cp "$(HOME)/.ssh/id_rsa.pub" $(data)
	docker run -v "$(data):/srv/data" -p 5050:80 server

run.puppet:
	$(call puppet,make run)

run.puppet.edit:
	$(call puppet,sh)

run.puppet.init:
	$(call puppet,make init)

clean: clean.ipxe clean.virsh clean.puppet clean.volumes

clean.ipxe:
	rm -rf "$(bin)/*"

clean.virsh:
	virsh list | awk '$$2 ~ /ipxe/ {system("virsh destroy " $$2)}'
	virsh list --all | awk '$$2 ~ /ipxe/ {system("virsh undefine " $$2)}'

clean.puppet:
	rm -rf puppet/puppetlabs/etc/puppet/ssl
	rm -rf puppet/puppetlabs/puppet/opt
	rm -rf puppet/puppetlabs/puppet/var

clean.volumes:
	virsh vol-list default | awk \
		'NR > 2 && NF > 0 {system("xargs virsh vol-delete --pool default " $$1)}'
