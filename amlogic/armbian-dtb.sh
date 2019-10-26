#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

#------------ $1, dtb file name in /media/$USER/BOOT/dtb/amlogic
main() 
{
	check_sdcard

	dtb_file="$1"
	if [ "X$1" = 'X' ]; then
		options=$(ls -1p "$BOOT_PATH/dtb/amlogic")
		#echo "$options" | grep -v / | grep -E '^meson.*.dtb$' | awk '{print NR "> " $s}'
		echo "$options" | grep -v / | grep -E '^meson.*.dtb$' | nl 
		echo ''
		read -p "Please select the INDEX : " user_select
		dtb_file=$(echo "$options" | sed -n "${user_select}p")
	fi

	if [ ! -f "$BOOT_PATH/dtb/amlogic/$dtb_file" ]; then
		log_y "Not found dtb file: $dtb_file"
		exit 1
	fi

	set_conf "$BOOT_PATH/uEnv.ini"
	set_conf 'dtb_name' "/dtb/amlogic/$dtb_file"

	echo "\n-------------- uEnv.ini -------"
	cat "$BOOT_PATH/uEnv.ini"

	extconf="$BOOT_PATH/extlinux/extlinux.conf"
	sed -i 's|\(.*/dtb/amlogic/\).*\.dtb$|\1'"$dtb_file"'|' $extconf

	echo "\n------------ extlinux.conf -----"
	cat $extconf |  grep -v -E '^\s*#'
}


main "$@"; exit $?
