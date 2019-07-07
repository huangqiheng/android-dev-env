#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	cd $ROOT_DIR/proxy

	check_apt proxychains
	cat > /etc/proxychains.conf <<-EOL
	strict_chain
	proxy_dns 
	tcp_read_time_out 15000
	tcp_connect_time_out 8000
	[ProxyList]
	socks5 127.0.0.1 6666
EOL

	if ! cmd_exists cloudflared; then
		cd $DATA_DIR
		check_sudo
		dpkg -i cloudflared-stable-linux-amd64.deb
	fi

	if pidof cloudflared; then
		pkill cloudflared
	fi

	echo 'nameserver 127.0.0.1' > /etc/resolv.conf
	proxychains cloudflared proxy-dns --address 127.0.0.1 &
	PIDS2KILL="$PIDS2KILL $!"

	cat > /tmp/sslocal-local6666.json <<-EOL
{
	"server":"127.0.0.1",
	"server_port":8388,
	"local_address": "0.0.0.0",
	"local_port":6666,
	"mode":"tcp_and_udp",
	"password":"bdzones",
	"timeout":600,
	"method":"aes-256-cfb"  	
}
EOL

	ss-local -c /tmp/sslocal-local6666.json &
	PIDS2KILL="$PIDS2KILL $!"

	sh openweb-inotify.sh

	kill $PIDS2KILL >/dev/null 2>&1
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
