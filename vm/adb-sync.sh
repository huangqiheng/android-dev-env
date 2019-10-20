#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if cmd_exists adb-sync; then
		log_y 'adb-sync already exists'
		adb-sync --help
		exit 
	fi

	check_sudo
	git clone https://github.com/google/adb-sync
	cd adb-sync
	cp adb-sync /usr/local/bin/
}

main "$@"; exit $?
