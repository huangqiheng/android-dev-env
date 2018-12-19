#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_update
	check_apt docker.io

	cd $RUN_DIR

	if [ ! -d mitm-router ]; then
		git clone https://github.com/brannondorsey/mitm-router
	fi
	cd mitm-router

	docker.io build . -t brannondorsey/mitm-router

	docker.io run -it --net host --privileged \
		-e AP_IFACE="wlan0" \
		-e INTERNET_IFACE="eth0" \
		-e SSID="PublicSSID" \
		-v "$(pwd)/data:/root/data" \
		brannondorsey/mitm-router
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
