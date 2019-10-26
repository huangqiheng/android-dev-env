#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	mode_name=$(adb devices -l | grep product | awk '{print $5}' | awk -F: '{print $2}')

	cd $CACHE_DIR
	mkdir -p $mode_name

	if [ "X$1" = 'X' ]; then
		ls -1p | grep -v / | grep -E 'backup-.*.ab$'
		log_y 'Please select the about file as parameter'
		exit 1
	fi

	adb restore "$CACHE_DIR/$mode_name/$1"
}

main "$@"; exit $?
