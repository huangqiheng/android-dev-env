#!/bin/dash

. $(dirname $(dirname $(dirname $(readlink -f $0))))/basic_functions.sh

main () 
{
	check_sudo
	check_apt libusb-dev git

	cd $CACHE_DIR
	if ! cmd_exists burn-tool; then
		if [ ! -d utils ]; then
			git clone https://github.com/khadas/utils
		fi
		cd utils
		git pull
		./INSTALL
	fi

	if ! lsusb | grep Amlogic; then
		log_y 'Please connect the board'
		exit 1
	fi

	cd utils/aml-flash-tool/tools/linux-x86
	./update identify

	empty_exit "$1" 'eMMC image to burnning'
	burn-tool -i "$1"
}

main "$@"; exit $?
