#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

AP_IFACE="${AP_IFACE:-wlan0}"

main () 
{
	log_y 'starting redsocks'

	nocmd_update redsocks
	check_apt redsocks

	# https://github.com/darkk/redsocks/blob/master/redsocks.conf.example
	cat > $CACHE_DIR/redsocks.conf <<-EOF
	base {
		log_debug = off;
		log_info = on;
		log = stderr;
		daemon = off;
		user = nobody;
		group = nobody;
		chroot = "/var/chroot";
		redirector = iptables;
	}
	redsocks {
		local_ip = 127.0.0.1;
		local_port = 12345;
		type = socks4;
		ip = 192.168.2.92;
		port = 3128;
	}
EOF

	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345

	cd $CACHE_DIR
	redsocks
	PIDS2KILL="$PIDS2KILL $!"

	waitfor_die "$(cat <<-EOL
	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 12345 > /dev/null 2>&1 || true
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
}

install_redsocks2()
{
	if ! cmd_exists redsocks2; then
		cd $CACHE_DIR
		if [ ! -d redsocks ]; then
			check_apt openssl libssl-dev libevent-dev
			git clone https://github.com/semigodking/redsocks.git
			cd redsocks 
			make
			#cp "$cmdPath" /usr/local/bin
		fi
	fi

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
