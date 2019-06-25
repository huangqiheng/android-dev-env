#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh


# https://askubuntu.com/questions/318973/how-do-i-create-a-wifi-hotspot-sharing-wireless-internet-connection-single-adap
# git clone https://github.com/oblique/create_ap.git

main () 
{

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
