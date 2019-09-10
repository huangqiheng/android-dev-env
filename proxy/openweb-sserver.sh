#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

openweb_image='openweb-sserver'

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

	CMD ["sh", "/root/ss-astrill.sh"]
EOL

	local bindport="${1:-8388}"
	local contname="ss-astrill-$bindport"

	if ! is_range $bindport 1024 49151; then
		log_r "port range invalid" 
		exit 1
	fi	

	local contid=$(cont_id $contname)

	gen_entrypoint /tmp/ss-astrill.sh
	gen_sstunnel_conf /tmp/sstunnel.json
	gen_sserver_conf /tmp/ssserver.json

	if [ -z $contid ]; then
		docker run -it --privileged \
			-e DISPLAY=$DISPLAY \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v $HOME/.Xauthority:/root/.Xauthority \
			-p "$bindport:8388" \
			-p "$bindport:8388/udp" \
			-v /tmp/sstunnel.json:/etc/sstunnel.json \
			-v /tmp/ssserver.json:/etc/ssserver.json \
			-v /tmp/ss-astrill.sh:/root/ss-astrill.sh \
			--hostname $(hostname) \
			--name "$contname" $openweb_image
		exit 0
	fi

	if cont_running $contname; then
		echo 'container is running'
		docker exec -it --user root "$contid" /bin/bash
		exit 0
	fi	

	docker start -ai "$contid"
}

gen_entrypoint()
{
	if [ -d "$1" ]; then
		rmdir "$1"
	fi

	cat > "$1" <<-EOL
	#!/bin/dash
	
    	ss-tunnel -c /etc/sstunnel.json -L 8.8.8.8:53 &
	ss-server -d 127.0.0.1:65353 -c /etc/ssserver.json &

	/usr/local/Astrill/astrill
EOL
}


gen_sserver_conf()
{
	if [ -d "$1" ]; then
		rmdir "$1"
	fi

	cat > "$1" <<-EOL
{
	"server":"0.0.0.0",
	"server_port":8388,
	"mode":"tcp_and_udp",
	"password":"bdzones",
	"timeout":600,
	"method":"aes-256-cfb"  	
}
EOL
}

gen_sstunnel_conf()
{
	if [ -d "$1" ]; then
		rmdir "$1"
	fi

	cat > "$1"  <<-EOL
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


