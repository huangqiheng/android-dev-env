#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	userName="$1"
	passWord="$2"

	if [ -z $userName ] || [ -z $passWord ]; then
		show_help_exit
	fi

	useradd -p $(openssl passwd -1 $passWord) $userName
	usermod -aG sudo $userName
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL
	sudo sh sudo-user.sh USERNAME PASSWORD
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
