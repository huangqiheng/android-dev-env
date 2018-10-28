#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	cd $DATA_DIR
	if [ ! -f ARM_Translation_Oreo.zip ]; then
		https://github.com/color0e/Oreo_Arm_trans/raw/master/ARM_Translation_Oreo.zip
	fi

	adb push --sync ARM_Translation_Oreo.zip /sdcard/Download/
	adb shell flash-archive.sh /sdcard/Download/ARM_Translation_Oreo.zip
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
