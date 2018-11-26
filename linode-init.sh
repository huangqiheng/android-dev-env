#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	userName=$1
	passWord=$2
	useradd -m $userName -p $passWord --groups sudo

	cd /root/$userName
	midir .ssh
	chmod 700 .ssh

	cd .ssh
	touch authorized_keys
	chmod 600 authorized_keys
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
