#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt polipo

	set_conf '/etc/polipo/config'
	set_conf socksParentProxy '127.0.0.1:7070'
	set_conf socksProxyType socks5
	set_conf proxyAddress '::0'
	set_conf proxyPort 8213

	service polipo restart
	
	cat << EOL
trys:
    npm config set proxy http://127.0.0.1:8213
    npm config set https-proxy http://127.0.0.1:8213
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
