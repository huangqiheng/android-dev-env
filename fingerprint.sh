#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ "$1" = 'gui' ]; then
		check_update 'ppa:fingerprint/fingerprint-gui'
		check_apt libbsapi policykit-1-fingerprint-gui fingerprint-gui
		fingerprint-gui
	else
		check_update 'ppa:fingerprint/fprint'
		check_apt libfprint0 fprint-demo libpam-fprintd
		fprint_demo
	fi
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
