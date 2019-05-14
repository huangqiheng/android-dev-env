#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt dfu-programmer

	cd $CACHE_DIR
	if [ ! -d tkg-toolkit ]; then
		git clone https://github.com/kairyu/tkg-toolkit
	fi
	cd tkg-toolkit/linux



}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
