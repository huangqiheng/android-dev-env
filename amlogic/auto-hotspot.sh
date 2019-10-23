#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

boot_dir=/media/${RUN_USER}/BOOT
root_dir=/media/${RUN_USER}/ROOTFS
apssid="${APSSID:-ArmbianHotspot}"
appass="${APPASS:-DontConnectMe}"; appass="${1:-$appass}"
rootpass="${ROOTPASS:-armbianrootpass}"; rootpass="${2:-$rootpass}"

main () 
{
	check_sdcard
	auto_login_root "$rootpass"
	entry_code
}

entry_code()
{
	handle_rc "${root_dir}/root/.bashrc" 'entry_point.sh' "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then sh /root/entry_point.sh; fi"

	cat > "${root_dir}/root/entry_point.sh" <<-EOL
	#!/bin/dash
	while true; do
		ifconfig -a
		iwconfig
	don
EOL

}

check_sdcard()
{
	if [ ! -d $root_dir ]; then
		check_sudo

		bootPart=$(lsblk -fp | grep "vfat.*BOOT " | head -1 | grep -oP '(/dev/\w*)')
		rootPart=$(lsblk -fp | grep "ext4.*ROOTFS" | head -1 | grep -oP '(/dev/\w*)')
		boot_dir=/tmp/${RUN_USER}/BOOT
		root_dir=/tmp/${RUN_USER}/ROOTFS

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
	fi

	if [ ! -d $boot_dir/uEnv.ini ]; then
		log_y 'Please plug in the armbian sd card'
		exit 2
	fi
}



auto_login_root()
{
	encpass=$(echo "$1" | mkpasswd --method=SHA-512 --stdin)
	shadow_file=${root_dir}/etc/shadow

	sed -i 's,^\(root:\)[^:]*\(:.*\)$,\1'"$encpass"'\2,' $shadow_file

	rm -f ${root_dir}/root/.not_logged_in_yet

	cat > ${root_dir}/lib/systemd/system/getty@tty1.service.d/20-autologin.conf <<-EOL
	[Service]
	ExecStart=
	ExecStart=-/sbin/agetty --autologin root --noclear %I \$TERM
EOL
}

main "$@"; exit $?
