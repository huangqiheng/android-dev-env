#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	local input_name="$1"
	echo "$input_name" > /etc/hostname

	handle_rc '/etc/hosts' "127.0.0.1 ${input_name}\n"

	set_conf '/etc/cloud/cloud.cfg'
	set_conf preserve_hostname true ':'
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
