#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	if cmd_exists websocat; then
		log_y 'websocat is ready'
		return 0 
	fi

	check_apt gdebi-core

	cd $CACHE_DIR
	if [ ! -f 'websocat_1.5.0_ssl1.0_amd64.deb' ]; then
		wget https://github.com/vi/websocat/releases/download/v1.5.0/websocat_1.5.0_ssl1.0_amd64.deb
	fi

	gdebi -n websocat_1.5.0_ssl1.0_amd64.deb
}

main "$@"; exit $?
