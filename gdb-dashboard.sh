#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	cd $UHOME

	if [ -f .gdbinit ]; then
		log "gdb-dashboard  has been installed"
		exit
	fi

	setup_gotty
	wget -P ~ git.io/.gdbinit
	chownUser $UHOME/.gdbinit
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
