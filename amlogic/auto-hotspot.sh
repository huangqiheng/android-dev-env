#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

boot_dir=/media/${RUN_USER}/BOOT
root_dir=/media/${RUN_USER}/ROOTFS
apssid="${APSSID:-ArmbianHotspot}"
appass="${APPASS:-DontConnectMe}"; appass="${1:-$appass}"
rootpass="${ROOTPASS:-armbianrootpass}"; rootpass="${2:-$rootpass}"

#------ $1, wifi pass
#------ $2, Linux os root's pass
main() 
{
	check_sdcard
	auto_login_root "$rootpass"

	entry_code  <<-EOL
	#!/bin/dash
	AP_IFACE=\$(iwconfig 2>/dev/null |  grep ESSID | head -1 | awk '{print \$1}')
	export IFAC=\${AP_IFACE}
	export SSID="${apssid}"
	export PASS="${appass}"
	sh /root/armbian-hostapd.sh
EOL

}

entry_code()
{
	echo "$(cat /dev/stdin)" > "${root_dir}/root/entry_point.sh"
	handle_rc "${root_dir}/root/.bashrc" 'entry_point.sh' "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then sh /root/entry_point.sh; fi"

	cp $DATA_DIR/dhcpserver-master.zip ${root_dir}/root/
	cp $ROOT_DIR/basic_mini.sh ${root_dir}/root/
	cp $EXEC_DIR/armbian-hostapd.sh ${root_dir}/root/
}

check_sdcard()
{
	while true;
	do
		if [ -d $root_dir ]; then
			break	
		fi

		boot_dir=/tmp/${RUN_USER}/BOOT
		root_dir=/tmp/${RUN_USER}/ROOTFS

		if [ -d $root_dir ]; then
			break	
		fi

		check_sudo
		
		bootPart=$(lsblk -fp | grep "vfat.*BOOT " | head -1 | grep -oP '(/dev/\w*)')
		rootPart=$(lsblk -fp | grep "ext4.*ROOTFS" | head -1 | grep -oP '(/dev/\w*)')

		if [ -z $bootPart ]; then
			log_y 'Not found Armbian SDCARD'
			exit 1
		fi

		if [ ! -d $boot_dir/dtb ]; then
			log_y 'Mount Armbian SDCARD'

			mkdir -p $boot_dir; umount -f $boot_dir >/dev/null 2>&1
			mkdir -p $root_dir; umount -f $root_dir >/dev/null 2>&1
			mount $bootPart $boot_dir
			mount $rootPart $root_dir
		fi
	done

	if [ ! -f $boot_dir/uEnv.ini ]; then
		log_y 'Please plug in the armbian sd card'
		exit 2
	fi
}



auto_login_root()
{
	check_apt whois
	encpass=$(echo "$1" | mkpasswd --method=SHA-512 --stdin)
	shadow_file=${root_dir}/etc/shadow

	sed -i 's,^\(root:\)[^:]*\(:.*\)$,\1'"$encpass"':::::::,' $shadow_file

	rm -f ${root_dir}/root/.not_logged_in_yet

	cat > ${root_dir}/lib/systemd/system/getty@tty1.service.d/20-autologin.conf <<-EOL
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOL
}

main "$@"; exit $?
