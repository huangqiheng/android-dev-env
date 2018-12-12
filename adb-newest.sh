#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	adb_root=$UHOME/Android

	mkdir -p $adb_root 
	cd $adb_root

	if [ ! -f platform-tools-latest-linux.zip ]; then
		wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip 
	fi
	unzip platform-tools-latest-linux.zip

	bashrc 'platform-tools/adb' "PATH=\$PATH:$adb_root/platform-tools"
	adb version
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
