#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	set_conf '/etc/default/grub'
	set_conf GRUB_DISTRIBUTOR "\'$1\'"
	update-grub2
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
