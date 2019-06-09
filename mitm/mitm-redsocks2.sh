#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

LAN_IFACE="${LAN_IFACE:-wlan0}"

set_redsocks()
{
	sed -ri "s|^\s*${1}\s*=.*|${1}=${2};|" /etc/redsocks.conf
}

main () 
{
	log_y 'starting redsocks2'

	nocmd_update redsocks2
	if ! cmd_exists redsocks2; then
		cd $CACHE_DIR
		if [ ! -d redsocks ]; then
			check_apt openssl libssl1.0-dev libevent-dev
			git clone https://github.com/semigodking/redsocks.git
			cd redsocks 
			make
			cp redsocks2 /usr/local/bin
		fi
	fi

	# https://github.com/darkk/redsocks/blob/master/redsocks.conf.example
	set_redsocks daemon off
	set_redsocks log_debug on
	set_redsocks log stderr
	set_redsocks redirector iptables
	set_redsocks local_ip 0.0.0.0
	set_redsocks type http-connect
	set_redsocks ip 192.168.2.92
	set_redsocks port 8080

	iptables -t nat -D PREROUTING -i $LAN_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i $LAN_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345

	redsocks2 -p /tmp/redsocks2.pid &
	PIDS2KILL="$PIDS2KILL $(cat /tmp/redsocks2.pid) $!"

	waitfor_die "$(cat <<-EOL
	iptables -t nat -D PREROUTING -i $LAN_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345 > /dev/null 2>&1 || true
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
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
