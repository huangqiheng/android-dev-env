#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	nocmd_update libreoffice

	if  uname -n | grep kali; then
		apt-get install libreoffice
	else
		add-apt-repository ppa:libreoffice/libreoffice-prereleases
		apt-get install libreoffice
	fi
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
