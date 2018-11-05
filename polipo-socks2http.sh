#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt polipo

	set_conf '/etc/polipo/config'
	set_conf socksParentProxy '127.0.0.1:1337'
	set_conf socksProxyType socks5
	set_conf proxyAddress '::0'
	set_conf proxyPort 8123

	service polipo restart
	
	cat << EOL
trys:
    npm config set proxy http://127.0.0.1:8123
    npm config set https-proxy http://127.0.0.1:8123
EOL
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
