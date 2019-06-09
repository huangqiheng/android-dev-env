#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

TARGET=atmega32u4
VER=
HEX=$ROOT_DIR/data/ok60hhkbgeneral.hex
# compile .hex file from https://kbfirmware.com/ use data/ok60hhkbgeneral.json

main () 
{
	check_apt dfu-programmer
	get_version

	echo "Erasing..."
	if [ "$VER" == "0.7" ]
	then
		dfu-programmer $TARGET erase --force
	else
		dfu-programmer $TARGET erase
	fi
	echo Reflashing HEX file...
	dfu-programmer $TARGET flash "$HEX"

	EXITCODE=$?
	if [ $EXITCODE -eq 0 ]
	then
		echo "Success!"
	else
		echo "Fail!"
	fi

	dfu-programmer $TARGET reset
	exit $EXITCODE
}

get_version() 
{
	VERINFO=$(dfu-programmer --version 2>&1)
	if [ $(echo $VERINFO | grep -c "0.6") -gt 0 ]
	then
		VER=0.6
	elif [ $(echo $VERINFO | grep -c "0.7") -gt 0 ]
	then
		VER=0.7
	else
		echo "dfu-programmer >= 0.6 not installed, please install first."
		exit 1
	fi
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
