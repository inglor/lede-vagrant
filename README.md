# lede-vagrant
Vagrant files for building LEDE project https://lede-project.org/

## Information
The VM is based on base box bento/debian-8.2 (https://atlas.hashicorp.com/bento/boxes/debian-8.2) This provides 40G of space on the VM

The provision for this build is done with SHELL and it's details are on `provision/provision.sh`

## Customize the VM configuration
The VM is currently build with 1/4 of system memory and all available CPUs of the host.

## Optional include your custom config
If you want to include your config on the VM then you should copy it under `build/` directory with name `myconfig`

## Instructions to get building LEDE
* install virtualbox https://www.virtualbox.org/wiki/Downloads
* install vagrant https://www.vagrantup.com/downloads.html
* clone this repo into a folder
* cd to the folder, and run `vagrant up`

This would do the following:
* download a debian base box image
* add the VM to VirtualBox and configure it
* spin up the VM
* execute the `provision/provision.sh` code which will:
  * update the VM (execute `apt-get update -y`)
  * mounts a shared folder between the host and the VM on `/vagrant_data`
  * install all dependencies required to build LEDE
  * clone the LEDE source code
  * update and install all LEDE feeds
  * copy the `build/myconfig` to `~/lede/.config` if provided
