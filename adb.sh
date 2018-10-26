#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	adb_root=$HOME/Android
	mkdir -p $adb_root 
	cd $adb_root

	if [ ! -f platform-tools-latest-linux.zip ]; then
		wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip 
	fi
	unzip platform-tools-latest-linux.zip

	bashrc=$HOME/.bash_aliases
	if [ ! -f $bashrc ]; then
		touch $bashrc 
	fi
	if ! grep -q "$adb_root/platform-tools/adb" $bashrc; then
		echo "alias adb=\"$adb_root/platform-tools/adb\"" >> $bashrc 
		echo "alias fastboot=\"$adb_root/platform-tools/fastboot\"" >> $bashrc
	fi

	source $bashrc
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
