#!/bin/bash
#
# provision.sh
#
# This file is specified in Vagrantfile and is loaded by Vagrant as the primary
# provisioning script whenever the commands `vagrant up`, `vagrant provision`,
# or `vagrant reload` are used. It provides all of the default packages and
# configurations included with Varying Vagrant Vagrants.

VM_USER=vagrant


# By storing the date now, we can calculate the duration of provisioning at the
# end of this script.
start_seconds="$(date +%s)"

# PACKAGE INSTALLATION
#
# Build a bash array to pass all of the packages we want to install to a single
# apt-get command. This avoids doing all the leg work each time a package is
# set to install. It also allows us to easily comment out or add single
# packages. We set the array as empty to begin with so that we can append
# individual packages to it as required.
apt_package_install_list=()

# Start with a bash array containing all packages we want to install in the
# virtual machine. We'll then loop through each of these and check individual
# status before adding them to the apt_package_install_list array.
apt_package_check_list=(
  build-essential
  libssl-dev
  libncurses5-dev
  unzip
  gawk
  git
  python
  subversion
  mercurial
  wget
  g++
  zlib1g-dev
  gettext
  file
  htop
  ccache
  ntp
  vim
)

### FUNCTIONS

network_detection() {
  # Network Detection
  #
  # Make an HTTP request to google.com to determine if outside access is available
  # to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
  # skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
    echo "Network connection detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach google.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}

noroot() {
  sudo -EH -u "${VM_USER}" "$@";
}

not_installed() {
  dpkg -s "$1" 2>&1 | grep -q 'Version:'
  if [[ "$?" -eq 0 ]]; then
    apt-cache policy "$1" | grep 'Installed: (none)'
    return "$?"
  else
    return 0
  fi
}

print_pkg_info() {
  local pkg="$1"
  local pkg_version="$2"
  local space_count
  local pack_space_count
  local real_space

  space_count="$(( 20 - ${#pkg} ))" #11
  pack_space_count="$(( 30 - ${#pkg_version} ))"
  real_space="$(( space_count + pack_space_count + ${#pkg_version} ))"
  printf " * $pkg %${real_space}.${#pkg_version}s ${pkg_version}\n"
}

package_check() {
  # Loop through each of our packages that should be installed on the system. If
  # not yet installed, it should be added to the array of packages to install.
  local pkg
  local pkg_version

  for pkg in "${apt_package_check_list[@]}"; do
    if not_installed "${pkg}"; then
      echo " *" "$pkg" [not installed]
      apt_package_install_list+=($pkg)
    else
      pkg_version=$(dpkg -s "${pkg}" 2>&1 | grep 'Version:' | cut -d " " -f 2)
      print_pkg_info "$pkg" "$pkg_version"
    fi
  done
}

package_install() {
  package_check

  if [[ ${#apt_package_install_list[@]} = 0 ]]; then
    echo -e "No apt packages to install.\n"
  else
    # Update all of the package references before installing anything
    echo "Running apt-get update..."
    apt-get -y update
    # Install required packages
    echo "Installing apt-get packages..."
    apt-get -y install ${apt_package_install_list[@]}
    # Remove unnecessary packages
    echo "Removing unnecessary packages..."
    apt-get autoremove -y
    # Clean up apt caches
    apt-get clean
  fi
}

configure_ccache() {
  echo -e "\nexport PATH=/usr/lib/ccache:$PATH" >> /home/${VM_USER}/.bashrc
}

get_lede() {
  if [[ -d "/home/${VM_USER}/lede" ]]; then
    echo "LEDE project source cloned, pulling latest HEAD for origin/master"
    cd "/home/${VM_USER}/lede"
    noroot git checkout master
    noroot git pull origin
  else
    echo "Cloning LEDE project source in /home/${VM_USER}/lede"
    noroot git clone https://github.com/lede-project/source.git /home/${VM_USER}/lede
  fi
  echo "Updating and installing feeds"
  noroot /home/${VM_USER}/lede/scripts/feeds update -a
  noroot /home/${VM_USER}/lede/scripts/feeds install -a

  if [[ -f "/vagrant_data/config/myconfig" ]]; then
    echo "Copying /vagrant_data/config/myconfig to /home/${VM_USER}/lede/.config"
    cp "/vagrant_data/config/myconfig" "/home/${VM_USER}/lede/.config" 
  fi
}

### SCRIPT
#set -xv

network_check
# Package and Tools Install
echo "Installing dependencies"
package_install
configure_ccache
echo "Getting LEDE"
get_lede

# And it's done
end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$(( end_seconds - start_seconds ))" seconds"
echo "To build the LEDE project: ssh, and cd ~/lede, then make menuconfig, then make"
echo "  vagrant ssh"
echo "  cd ~/lede"
echo "  make defconfig"
echo "  make menuconfig"
echo "  make -j$(nproc) V=99"
echo -e "After compilation has finished, copy the result to the host machine:\\n  cp bin/*/*.{bin,img} /vagrant_data/build\\n  cp .config /vagrant_data/build/config"
