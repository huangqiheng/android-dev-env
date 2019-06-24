#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	read -p 'Input Socks5 SERVER [127.0.0.1]: ' SOCKSSERVER
	SOCKSSERVER=${SOCKSSERVER:-'127.0.0.1'}

	read -p 'Input Socks5 PORT [6666]: ' SOCKSPORT
	SOCKSPORT=${SOCKSPORT:-'6666'}

	log_y "Socks5: $SOCKSSERVER : $SOCKSPORT"

	git config --global http.proxy "socks://$SOCKSSERVER:$SOCKSPORT"

}

clean_exit()
{
	git config --global http.proxy ''
	exit 0
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'clean' ] && clean_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
