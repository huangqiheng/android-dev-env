#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if ! cmd_exists adb-sync; then
		check_sudo 
		cd $EXEC_DIR
		sh adb_sync.sh
	fi

	mode_name=$(adb devices -l | grep product | awk '{print $5}' | awk -F: '{print $2}')

	if [ "X$mode_name" = 'X' ]; then
		log_y 'devices not found'
		exit 1
	fi

	cd $CACHE_DIR
	mkdir -p $mode_name 
	cd $mode_name

	mkdir -p devicetree
	adb-sync -R /sys/firmware/devicetree/base ./devicetree
}

main "$@"; exit $?
