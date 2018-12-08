#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt git live-build cdebootstrap

	cd $CACHE_DIR
	if [ ! -d live-build-config ]; then
		git clone git://git.kali.org/live-build-config.git
	fi

	cd live-build-config
	./build.sh --distribution kali-rolling --verbose
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
