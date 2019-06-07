#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	# Realtek rtl8812au
	check_apt rtl8812au-dkms
	
	# Ralink Technology, Corp. MT7601U Wireless Adapter
	# https://askubuntu.com/questions/457061/ralink-mt7601u-148f7601-wi-fi-adapter-installation
	check_apt firmware-misc-nonfree


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
