#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	mode_name=$(adb devices -l | grep product | awk '{print $5}' | awk -F: '{print $2}')

	cd $CACHE_DIR
	mkdir -p $mode_name
	filename="backup-$(date +"%Y-%m-%d_%H-%M-%S").ab"

	adb backup -apk -shared -all -f $filename
	log_y "backup file: $filename"
}

main "$@"; exit $?
