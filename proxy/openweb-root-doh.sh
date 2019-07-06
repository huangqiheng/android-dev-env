#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

openweb_image='openweb-sserver-root'

main () 
{
	build_image $openweb_image <<-EOL
	FROM ubuntu:18.04
	COPY ./astrill-setup-linux64.deb /root
	COPY ./cloudflared-stable-linux-amd64.deb /root

	RUN apt-get update \\
	    && apt-get install -y openssl libssl-dev \\
	    && apt-get install -y rng-tools shadowsocks-libev \\
	    && service shadowsocks-libev stop \\
	    && apt-get install -y vim net-tools psmisc iproute2 nscd dnsutils \\
	    && apt-get install -y libgtk2.0-0 libcanberra-gtk-module \\
	    && apt-get install -y gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \\
	    && apt-get install -y gnome-themes-standard \\
	    && dpkg -i /root/astrill-setup-linux64.deb \\
	    && apt-get autoremove

	RUN apt-get install -y libcap2-bin git gcc make automake libcurl4-gnutls-dev \\
	    && cd /root && git clone https://github.com/holmium/dnsforwarder.git \\
	    && cd dnsforwarder && ./configure && make && make install \\
	    && mkdir -p "/root/.dnsforwarder" \\
	    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/dnsforwarder \\
	    && apt-get autoremove

	RUN apt-get install -y inotify-tools \\
	    && dpkg -i /root/cloudflared-stable-linux-amd64.deb

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
	gen_dnsforwarder_conf /tmp/dnsforwarder.conf
	gen_sserver_conf /tmp/ssserver.json

	if [ -z $contid ]; then
		docker run -it --privileged \
			-e DISPLAY=$DISPLAY \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v $HOME/.Xauthority:/root/.Xauthority \
			-p "$bindport:8388" \
			-p "$bindport:8388/udp" \
			-v /tmp/dnsforwarder.conf:/etc/dnsforwarder.conf \
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
	cat > "$1" <<-EOL
	#!/bin/dash
	
	cloudflared proxy-dns --port 65353 &

	while inotifywait -e close_write /etc/resolv.conf; do 
		echo 'nameserver 127.0.0.1' > /etc/resolv.conf
	done &
	dnsforwarder -D -f /etc/dnsforwarder.conf &

	ss-server -c /etc/ssserver.json &

	/usr/local/Astrill/astrill
EOL
}


gen_sserver_conf()
{
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

gen_dnsforwarder_conf()
{
	cat > "$1"  <<-EOL
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


