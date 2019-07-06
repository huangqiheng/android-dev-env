#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh
. $ROOT_DIR/proxy/functions.sh

openweb_inotify='openweb-inotify'

main () 
{
	check_openweb_image

	build_image $openweb_inotify <<-EOL
	FROM openweb-proxychains-doh-sserver
	CMD ["sh", "/root/entrypoint.sh"]
EOL

	set_entrypoint <<-EEOL
	#!/bin/dash

	cat > /root/dnsforwarder.conf  <<-EOL
	LogOn false
	LogFileThresholdLength 5120000
	LogFileFolder /var/log
	UDPLocal 0.0.0.0:53
	UDPGroup 127.0.0.1:65353 * on
	BlockNegativeResponse true
	UseCache true
	MemoryCache false
	CacheSize 30720000
	IgnoreTTL true
	ReloadCache true
	OverwriteCache true
EOL
	cat > /etc/proxychains.conf <<-EOL
	strict_chain
	proxy_dns 
	tcp_read_time_out 15000
	tcp_connect_time_out 8000
	[ProxyList]
	socks5 127.0.0.1 6666
EOL
	cat > /root/ssserver.json <<-EOL
{
	"server":"0.0.0.0",
	"server_port":8388,
	"mode":"tcp_and_udp",
	"password":"bdzones",
	"timeout":600,
	"method":"aes-256-cfb"  	
}
EOL
	
	while inotifywait -e close_write /etc/resolv.conf; do 
		echo 'nameserver 127.0.0.1' > /etc/resolv.conf
	done &

    	mkdir -p "/root/.dnsforwarder"
	dnsforwarder -f /root/dnsforwarder.conf &

	cloudflared proxy-dns --port 65353 &
	ss-server -c /root/ssserver.json &

	/usr/local/Astrill/astrill
EEOL

	run_openweb "$1"
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


