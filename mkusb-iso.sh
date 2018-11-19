#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	check_update ppa:mkusb/ppa
	check_apt mkusb-nox gdisk
	check_apt grub-pc-bin

	echo "
       Make a USB install device from ISO or image file
           sudo mkusb-nox file.iso
           sudo -H mkusb file.iso p    # install a persistent live system
           sudo mkusb-nox \"quote file name (1) with special characters.iso\"
           sudo mkusb-nox path/file.iso
           sudo mkusb-nox file.img
           sudo mkusb-nox file.img.gz
           sudo mkusb-nox file.img.xz
           sudo mkusb-nox file.tar    # if an mkusb tarfile for Windows

       Install from 'file.img.xz', show all mass storage devices
           sudo mkusb-nox file.img.xz all

       Clone a device (typically a CD/DVD drive or USB drive)
           sudo mkusb-nox /dev/sr0    # example of CD drive

       Wipe the USB device (may take long time)
           sudo mkusb-nox wipe-whole-device

       Wipe the first megabyte (MibiByte), show only USB devices
           sudo mkusb-nox wipe-1

       Restore to a storage device
           sudo mkusb-nox restore  # FAT32 file system
           sudo -H mkusb wipe    # wipe menu (select suitable file systems)

       Wipe the first megabyte, show all mass storage devices
           sudo mkusb-nox wipe-1 all
"

}

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	sudo $0"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)\/ppa/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

check_apt()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			log "${package} has been installed"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

cmd_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
