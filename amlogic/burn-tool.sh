#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	if ! cmd_exists burn-tool; then
		check_apt libusb-dev git

		cd $CACHE_DIR
		if [ ! -d utils ]; then
			git clone https://github.com/khadas/utils
		fi
		cd utils
		git pull
		./INSTALL
	fi

	if ! lsusb | grep Amlogic; then
		log_y 'plseae set tv box in update mode'
		exit 1
	fi

	empty_exit "$1" 'The image to burn'
	burn-tool -i "$1"
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
