#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	log_y 'starting trudy'
	setup_github_go kelbyludwig truey
	check_apt iptables 

	trudy
	PIDS2KILL="$PIDS2KILL $!"

	waitfor_die "$(cat <<-EOL
	iptables -t nat -D PREROUTING -i "$AP_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337 > /dev/null 2>&1 || true
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
