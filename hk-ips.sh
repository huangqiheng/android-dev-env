#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

IFCE=enp1s0
GWAT=10.0.0.254
NMSK=255.255.255.0

main () 
{
	check_sudo
	add_ip 1 '10.0.0.23'

	add_ip 2 '59.188.84.62' '255.255.255.248'
}

add_ip()
{
	local index=$1
	local ip=$2
	local mask=$3

	if [ "X$mask" = 'X' ]; then
		mask=$NMSK
	fi
	
	if ifconfig | grep -iq "inet $ip"; then
		log_y "$ip has added"
		return 0
	fi
	ifconfig $IFCE:$index "$ip" netmask $mask
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
