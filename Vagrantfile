# -*- mode: ruby -*-
# vi: set ft=ruby :

vagrant_dir = File.expand_path(File.dirname(__FILE__))

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Use Debian 8 from bento because it contains a 40 GB hard disc instead of
  # a 10 GB hard disc in contrast to "debian/jessie64" 
  config.vm.box = "bento/debian-8.2"

  config.vm.provider :virtualbox do |v|
    host = RbConfig::CONFIG['host_os']
    # Give VM 1/4 system memory if mem > 2048M & access to all cpu cores on the host
    # This supports HyperThreading in Intel CPUs and will count them as cores (logical cores)
    # if you want to avoid that use `NumberOfCores` instead of `NumberOfLogicalProcessors`
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
      mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024
    elsif host =~ /linux/
      cpus = `nproc`.to_i
      mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024
    elsif host =~ /mswin|mingw|cygwin/
      cpus = `wmic cpu Get NumberOfLogicalProcessors`.split[1].to_i
      mem = `wmic computersystem Get TotalPhysicalMemory`.split[1].to_i / 1024 / 1024
    end
    mem = mem / 4  if mem > 2048
    v.customize ["modifyvm", :id, "--memory", mem]
    v.customize ["modifyvm", :id, "--cpus", cpus]
    v.name = "lede-buildvm"
  end
  config.vm.synced_folder ".", "/vagrant_data"
  config.vm.hostname = "lede-buildvm"
  config.vm.network "private_network", ip: "192.168.33.10"

  # provision.sh or provision-custom.sh
  #
  # By default, Vagrantfile is set to use the provision.sh bash script located in the
  # provision directory. If it is detected that a provision-custom.sh script has been
  # created, that is run as a replacement. This is an opportunity to replace the entirety
  # of the provisioning provided by default.
  if File.exists?(File.join(vagrant_dir,'provision','provision-custom.sh')) then
    config.vm.provision "custom", type: "shell", path: File.join( "provision", "provision-custom.sh" )
  else
    config.vm.provision "default", type: "shell", path: File.join( "provision", "provision.sh" )
  end
end
