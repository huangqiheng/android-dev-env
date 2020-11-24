#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	empty_exit "$1" 'dns name need.'
	set_conf /etc/systemd/resolved.conf
	set_conf DNS "$1"

	systemctl restart systemd-resolved
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL
	sudo sh systemd-resolved.sh 192.168.1.10
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
