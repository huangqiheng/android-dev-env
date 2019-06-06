#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

SUB_IFACE="${SUB_IFACE:-wlan0}"

main () 
{
	log_y 'starting trudy'

	setup_github_go kelbyludwig/trudy
	check_apt iptables 

	#iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080 > /dev/null 2>&1 || true
	#iptables -t nat -A PREROUTING -i $SUB_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080
	#iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443 > /dev/null 2>&1 || true
	#iptables -t nat -A PREROUTING -i $SUB_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443
	iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp -m multiport ! --dports 5223,443 -j REDIRECT --to-ports 6666 > /dev/null 2>&1 || true
	iptables -t nat -A PREROUTING -i $SUB_IFACE -p tcp -m multiport ! --dports 5223,443 -j REDIRECT --to-ports 6666

	cd "$(go env GOPATH)/src/github.com/kelbyludwig/trudy"
	trudy &
	PIDS2KILL="$PIDS2KILL $!"

	waitfor_die "$(cat <<-EOL
	#iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp --dport 8888 -m tcp -j REDIRECT --to-ports 8080 > /dev/null 2>&1 || true
	#iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp --dport 443 -m tcp -j REDIRECT --to-ports 6443 > /dev/null 2>&1 || true
	iptables -t nat -D PREROUTING -i $SUB_IFACE -p tcp -m multiport ! --dports 5223,443 -j REDIRECT --to-ports 6666 > /dev/null 2>&1 || true
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
}

iptables_chain_bypass_LAN() 
{
    # Add rule to iptables [$1: table] [$2: chain] to bypass LAN addresses.
    iptables -t $1 -A $2 -d 0.0.0.0/8 -j RETURN
    iptables -t $1 -A $2 -d 10.0.0.0/8 -j RETURN
    iptables -t $1 -A $2 -d 127.0.0.0/8 -j RETURN
    iptables -t $1 -A $2 -d 169.254.0.0/16 -j RETURN
    iptables -t $1 -A $2 -d 172.16.0.0/12 -j RETURN
    iptables -t $1 -A $2 -d 192.168.0.0/16 -j RETURN
    iptables -t $1 -A $2 -d 224.0.0.0/4 -j RETURN
    iptables -t $1 -A $2 -d 240.0.0.0/4 -j RETURN
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
