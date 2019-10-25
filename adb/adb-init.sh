#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo
	check_apt adb fastboot

	if adb devices 2>&1 | grep -iq 'no permissions'; then
		deviceids=$(lsusb | grep fastboot | awk '{print $6}' | head -1)
		idVendor=$(echo $deviceids | awk -F: '{print $1}')
		idProduct=$(echo $deviceids | awk -F: '{print $2}')
		log_y "device = $idVendor : $idProduct" 

		cat > /etc/udev/rules.d/51-android.rules <<-EOL
		SUBSYSTEM=="usb", ATTR{idVendor}=="${idVendor}", ATTR{idProduct}=="${idProduct}", MODE="0666", GROUP="plugdev"
EOL
		udevadm control --reload-rules
		log_y 'Reboot if needed.'
	fi

}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
