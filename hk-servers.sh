#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

IFCE=enp1s0
NMSK=255.255.255.0
GWAT=10.0.0.254
index=1

main () 
{
	check_sudo
	check_apt nmap

	if [ "$1" = 'kill' ]; then
		pkill ncat
		exit 0
	fi

	if [ "$1" = 'del' ]; then
		while true; do
			ifconfig $IFCE:$index down
			index=$(expr $index + 1)
		done
		exit 0
	fi

	IFS='
'
	set -- $SRVS; while [ "$1" != '' ]; do
		local hostport="$1"; shift
		local host=$(echo "$hostport" | cut -f1)
		local port=$(echo "$hostport" | cut -f2)

		if add_ip $index $host; then
			index=$(expr $index + 1)
		fi
		ncat -l $host $port -k -c 'xargs -n1 echo' &
	done
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
		return 1
	fi
	#ifconfig $IFCE:$index "$ip" netmask $mask broadcast 10.0.0.255 up
	ip addr add "$ip/24" dev $IFCE
	return 0
}


SRVS='
10.0.0.20	80
'

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
