#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt wine-development

	cd $CACHE_DIR
	wget https://dl.winhq.org/wine/wine-gecko/2.44/wine_gecko-2.44-x86_64.msi
	wine-development msiexec /i wine_gecko-2.44-x86_64.msi
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
