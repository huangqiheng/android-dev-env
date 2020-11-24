#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt proxychains

	mv /etc/proxychains.conf /etc/proxychains.conf.bk

	cat > /etc/proxychains.conf <<EOL
strict_chain
proxy_dns 
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5 	127.0.0.1 $1
EOL

	hide_ip=$(proxychains curl http://ifconfig.me)
	real_ip=$(curl http://ifconfig.me)

	log_y $hide_ip vs $real_ip

	mv /etc/proxychains.conf.bk /etc/proxychains.conf
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
