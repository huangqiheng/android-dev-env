#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ "$1" = 'client' ]; then
		check_apt fwknop-client
		fwknop -A tcp/2222 -D localhost --key-gen --use-hmac --save-rc-stanza
		cat $HOME/.fwknoprc
		exit
	fi

	check_apt rng-tools
	rngd -r /dev/urandom
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
