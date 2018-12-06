#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if  uname -n | grep kali; then
		cd $CACHE_DIR
		if [ ! -f mkusb-nox ]; then
			wget https://phillw.net/isos/linux-tools/mkusb/mkusb-nox 
		fi
		cp mkusb-nox /usr/bin/
		chown root:root /usr/bin/mkusb-nox
		chmod a+x /usr/bin/mkusb-nox
	else
		check_update ppa:mkusb/ppa
		check_apt mkusb-nox gdisk
		check_apt grub-pc-bin grub-efi-amd64-bin
	fi

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

main "$@"; exit $?
