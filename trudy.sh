#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

AP_IFACE="${AP_IFACE:-wlan0}"

main () 
{
	log_y 'starting trudy'

	setup_github_go kelbyludwig/trudy
	check_apt iptables 

	#iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080 > /dev/null 2>&1 || true
	#iptables -t nat -A PREROUTING -i $AP_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080
	#iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443 > /dev/null 2>&1 || true
	#iptables -t nat -A PREROUTING -i $AP_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443
	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 6666 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 6666


	cd "$(go env GOPATH)/src/github.com/kelbyludwig/trudy"
	trudy &
	PIDS2KILL="$PIDS2KILL $!"

	waitfor_die "$(cat <<-EOL
	#iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080 > /dev/null 2>&1 || true
	#iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443 > /dev/null 2>&1 || true
	iptables -t nat -D PREROUTING -i $AP_IFACE -p tcp -m tcp -j REDIRECT --to-ports 6666 > /dev/null 2>&1 || true
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
