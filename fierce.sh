#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if ! cmd_exists fierce; then
		check_update
		check_apt python3-pip
		pip3 install fierce
	fi

	domain="${1:-baidu.com}"
	fierce --domain $domain --dns-servers 8.8.8.8
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
