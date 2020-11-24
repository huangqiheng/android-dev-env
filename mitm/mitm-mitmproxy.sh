#!/bin/dash

. $(dirname $(readlink -f $0))/basic_mini.sh

LAN_IFACE="${LAN_IFACE:-wlan0}"
CAPTURE_FILE="${CAPTURE_FILE:-/home/http-traffic.cap}"

main () 
{
	log_y 'starting mitmproxy'

	nocmd_update mitmdump
	check_apt iptables 

	if ! cmd_exists mitmdump; then
		cd /home
		if [ ! -f mitmproxy-4.0.4-linux.tar.gz ]; then
			check_apt wget
			wget https://snapshots.mitmproxy.org/4.0.4/mitmproxy-4.0.4-linux.tar.gz
		fi
		tar -xzvf mitmproxy-4.0.4-linux.tar.gz --directory=/usr/bin
	fi

	mitmdump --mode transparent \
		--showhost \
		--rawtcp \
		--listen-port 1337 \
		--save-stream-file "$CAPTURE_FILE" "$FILTER" &
	PIDS2KILL="$PIDS2KILL $!"

	iptables -t nat -D PREROUTING -i "$LAN_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i "$LAN_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337

	waitfor_die "$(cat <<-EOL
	iptables -t nat -D PREROUTING -i "$LAN_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337 > /dev/null 2>&1 || true
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
	return 0
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat <<- EOL
	LAN_IFACE=wlan0 sudo sh $(basename $BASIC_SCRIPT)
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
