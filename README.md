Tortank server setup
====================

This repository contains mainly the development environment in order to
boot and provision my personal home server.

It consists in multiple Docker images and a kvm instance, all of this is mostly
managed with this [Makefile](./Makefile).

The machine is a Debian, bootstraped with iPXE, after the installation
[a script](./netboot/install.sh) is ran in order to setup some basic config
for ssh and puppet setup of the machine.

Prerequisites
-------------

* [Docker](https://www.docker.com/)
* [Make](https://www.gnu.org/software/make/)
* kvm, qemu, virsh

Setup a [dnsdock container](https://github.com/tonistiigi/dnsdock)
as our docker DNS it will serve for the puppet part. Here are
[the systemd files](https://github.com/IxDay/dotfiles/tree/534be8ec2ad620896f9e1195f4387f579140b1d5/etc/systemd/system)
I use for launching it at boot.

My user is part of the `kvm` group and I launched the virtual machines on
the system socket `qemu:///system`. I also use the `default` network provided
by libvirt.

Workflow
--------

*NOTE:* A lot of command will block your shells, this is normal and avoid doing
too much things under the hood.

`git clone --recursive https://github.com/T0rt4nk/setup tortank`
clone the repository, then move into it (the make command needs to be run where
the Makefile is).


`make img` build the first containers, which will be the
[iPXE](./dockerfile_ipxe) building container, and
[a static file server](./dockerfile_server) which serve some files for
provisioning the virtual machine.

`make build.script` build the iPXE binary with
[a custom ipxe script embed](./scripts/script.ipxe). This script tell the pxe
boot to chain on a script which is on our file server. It avoids compiling
the iPXE binary each time we want to modify it.

`make run.server` retrieve the debian kernel and initrd and place them in
the [netboot](./netboot) directory.
They will be launched by the netboot with some additionnal options specified
in the [script on which pxe will chain](./netboot/ipxelinux.0).
After copying those files a server is started on the port `5050`. It will
provide everything in the `netboot` directory.

`make run.virsh` now that the server is running, let's boot the VM. You will
see some movement in the server as the netboot retrieve files for bootstraping
the machine. In order:
* `ipxelinux.0` the script on which the netboot chain
* `linux` a linux kernel
* `initrd.gz` an initrd which contains the debian installation process
* `preseed.cfg` a file [documented by debian](https://www.debian.org/releases/stable/amd64/apbs03.html.en) which automates the answer questions. As we are using netbooting
some options have to be passed directly to the kernel, you can see them in
the [ixpe script](./netboot/ipxelinux.0).
* `install.sh` a file which will finalize the installation. Add packages, setup
some systemd and scripts needed in the future.
* `id_rsa.pub` this is my public key, which will automatize my ssh connection
(this has been copied manually), it is asked by the `install.sh` script.

`virsh start ipxe` after this file as been charged the VM will stop
(`virsh list --all`). we need to start it again. It will register through a
`systemd` script to `dnsdock`

`make ssh` after a few seconds you are now able to ssh into your new VM.
As we are in development mode `puppet agent` has been disabled and a Makefile
is now in the `/root` directory. So, we need to ssh as root, `sudo su && cd`,
no password needed here (thanks to `install.sh`).

`make img.puppet` build the docker image for the puppet master instance.

`make run.puppet.init` initialize the puppet master, with the `tortank` puppet
module. This download the dependencies and symlink
[tortank directory](./tortank) to puppet master.

`make run.puppet` start the puppet master container.

Now, you can go back to the VM and run the `make` command as root. It will
launch the agent, retrieve the master and execute puppet configuration.

