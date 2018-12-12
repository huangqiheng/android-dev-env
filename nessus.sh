#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	setup_pup

	local TOKEN=$(curl -L -s https://www.tenable.com/products/nessus/agent-download | pup 'div#timecheck text{}')
	local FILE="NessusAgent-7.1.2-ubuntu1110_amd64.deb"
	local URL="https://downloads.nessus.org/nessus3dl.php?file=$FILE&licence_accept=yes&t=$TOKEN"

	log_r $URL

	cd $CACHE_DIR
	wget $URL
	
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
