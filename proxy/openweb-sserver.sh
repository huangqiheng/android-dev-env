#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

openweb_image='openweb-sserver'
bindport="${1:-8388}"


main () 
{
	build_image $openweb_image <<-EOL
	FROM ubuntu:18.04
	COPY ./astrill-setup-linux64.deb /root

	RUN apt-get update \\
	    && apt-get install -y vim net-tools psmisc iproute2 dnsutils  \\
	    && apt-get autoremove

	RUN apt-get update --fix-missing \\
	    && apt-get install -y openssl libssl-dev rng-tools \\
	    && apt-get install -y shadowsocks-libev \\
	    && service shadowsocks-libev stop \\
	    && apt-get autoremove

	RUN apt-get update --fix-missing \\
	    && apt-get install -y nscd libgtk2.0-0 libcanberra-gtk-module \\
	    && apt-get install -y gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \\
	    && apt-get install -y gnome-themes-standard \\
	    && dpkg -i /root/astrill-setup-linux64.deb \\
	    && apt-get autoremove

	CMD ["sh", "/root/entrypoint.sh"]
EOL

	start_openweb "$bindport" "$(cat <<-EEOL
	#!/bin/dash

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

	cat > /root/sstunnel.json <<-EOL
{
        "server":"${SSSERVER}",
        "password":"${SSPASSWD}",
        "server_port":16666,
        "mode":"tcp_and_udp",
	"local_address": "127.0.0.1",
	"local_port":65353,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL

    	ss-tunnel -v -c /root/sstunnel.json -L 8.8.8.8:53 &
	ss-server -v -d 127.0.0.1:65353 -c /root/ssserver.json &
	/usr/local/Astrill/astrill

EEOL
)"

}

ss_client_exit()
{
	check_apt shadowsocks-libev

	cat > /etc/shadowsocks-libev/sslocal.json <<-EOL
{
	"server":"127.0.0.1",
	"server_port":8388,
	"local_port":7070,
	"mode":"tcp_and_udp",
	"password":"bdzones",
	"method":"aes-256-cfb",
	"timeout":600
}
EOL

	ss-local -c /etc/shadowsocks-libev/sslocal.json
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'client' ] && ss_client_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?


