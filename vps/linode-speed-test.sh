#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

SRVS='
http://speedtest.newark.linode.com/100MB-newark.bin
http://speedtest.atlanta.linode.com/100MB-atlanta.bin
http://speedtest.dallas.linode.com/100MB-dallas.bin
http://speedtest.fremont.linode.com/100MB-fremont.bin
http://speedtest.toronto1.linode.com/100MB-toronto.bin
http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin
http://speedtest.london.linode.com/100MB-london.bin
http://speedtest.singapore.linode.com/100MB-singapore.bin
http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin
'

main () 
{
	IFS='
'
	set -- $SRVS; while [ "$1" != '' ]; do
		local down_url="$1"; shift
		wget --output-document=/dev/null "$down_url"
	done
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
