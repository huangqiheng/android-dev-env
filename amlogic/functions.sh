
get_partition_path()
{
	devName=${1:-boot}
	devdir=$(adb shell find /dev -name 'by-name' 2>/dev/null)
	adb shell ls -la $devdir | grep $devName | head -1 | awk '{print $10}'
}

PULLED_IMG=

pull_partition()
{
	local fromdev="$1"
	local outname=$(basename $fromdev).img
	local tofile=/data/local/tmp/$outname

	adb shell su -c "dd if=$fromdev of=$tofile bs=4096"
	adb shell su -c "chown shell.shell $tofile"
	adb pull $tofile $CACHE_DIR/$outname

	PULLED_IMG=$CACHE_DIR/$outname
	log_y "Got it: PULLED_IMG=$PULLED_IMG"
}

check_split_bootimg()
{
	if cmd_exists split_bootimg.pl; then
		log_y 'split_bootimg.pl is ready'
		return
	fi

	cd $CACHE_DIR
	if [ ! -f split_bootimg.pl ]; then
		wget -c http://www.enck.org/tools/split_bootimg_pl.txt -O split_bootimg.pl
		chmod a+x split_bootimg.pl
	fi
	
	check_sudo
	cp split_bootimg.pl /usr/local/bin
}


BOOT_PATH=/media/${RUN_USER}/BOOT
ROOT_PATH=/media/${RUN_USER}/ROOTFS

check_sdcard()
{
	while true;
	do
		if [ -d $ROOT_PATH ]; then
			break	
		fi

		BOOT_PATH=/tmp/${RUN_USER}/BOOT
		ROOT_PATH=/tmp/${RUN_USER}/ROOTFS

		if [ -d $ROOT_PATH ]; then
			break	
		fi

		bootPart=$(lsblk -fp | grep "vfat.*BOOT " | head -1 | grep -oP '(/dev/\w*)')
		rootPart=$(lsblk -fp | grep "ext4.*ROOTFS" | head -1 | grep -oP '(/dev/\w*)')

		if [ -z $bootPart ]; then
			log_y 'Not found Armbian SDCARD'
			exit 1
		fi

		if [ ! -d $BOOT_PATH/dtb ]; then
			log_y 'Mount Armbian SDCARD'

			check_sudo
		
			mkdir -p $BOOT_PATH; umount -f $BOOT_PATH >/dev/null 2>&1
			mkdir -p $ROOT_PATH; umount -f $ROOT_PATH >/dev/null 2>&1
			mount $bootPart $BOOT_PATH
			mount $rootPart $ROOT_PATH
		fi
	done

	if [ ! -f $BOOT_PATH/uEnv.ini ]; then
		log_y 'Please plug in the armbian sd card'
		exit 2
	fi
}

