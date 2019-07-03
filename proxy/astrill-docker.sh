#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

astrill_image='astrill-ubuntu'
USERNAME=$RUN_USER
PASSWORD=password

main () 
{
	build_image $astrill_image <<-EOL
	FROM ubuntu:18.04
	COPY ./astrill-setup-linux64.deb /root

	RUN apt-get update \\
	    && apt-get install -y libcap2-bin git gcc make automake libcurl4-gnutls-dev \\
	    && cd /root && git clone https://github.com/holmium/dnsforwarder.git \\
	    && cd dnsforwarder && ./configure && make && make install \\
	    && mkdir -p "/home/$USERNAME/.dnsforwarder" \\
	    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/dnsforwarder \\
	    && apt-get autoremove

	RUN apt-get install -y openssl libssl-dev \\
	    && apt-get install -y rng-tools shadowsocks-libev \\
	    && service shadowsocks-libev stop \\
	    && apt-get install -y vim net-tools psmisc iproute2 nscd dnsutils \\
	    && apt-get install -y libgtk2.0-0 libcanberra-gtk-module \\
	    && apt-get install -y gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \\
	    && apt-get install -y gnome-themes-standard \\
	    && useradd -m -p \$(openssl passwd -1 $PASSWORD) -s /bin/bash $USERNAME \\
	    && dpkg -i /root/astrill-setup-linux64.deb \\
	    && apt-get autoremove

	RUN echo '#!/bin/dash' > /usr/local/bin/ss-astrill \\
	    && echo 'ss-tunnel -c /etc/shadowsocks-libev/sstunnel.json -L 8.8.8.8:53 &' >> /usr/local/bin/ss-astrill \\
	    && echo 'dnsforwarder -D -f /etc/dnsforwarder.conf &' >> /usr/local/bin/ss-astrill \\
	    && echo 'ss-server -c /etc/shadowsocks-libev/ssserver.json &' >> /usr/local/bin/ss-astrill \\
	    && echo '/usr/local/Astrill/astrill' >> /usr/local/bin/ss-astrill \\
	    && chmod a+x /usr/local/bin/ss-astrill \\
	    && chown $USERNAME:$USERNAME /home/$USERNAME -R
	USER $USERNAME
	ENV HOME /home/$USERNAME
	CMD ss-astrill
EOL

	cat > /tmp/sstunnel.json <<-EOL
{
        "server":"173.242.116.99",
        "password":"5dont6share7pass8",
        "server_port":16666,
        "mode":"tcp_and_udp",
	"local_address": "127.0.0.1",
	"local_port":65353,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL

	cat > /tmp/dnsforwarder.conf <<-EOL
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

	cat > /tmp/ssserver.json <<-EOL
{
	"server":"0.0.0.0",
	"server_port":8388,
	"mode":"tcp_and_udp",
	"password":"bdzones",
	"timeout":600,
	"method":"aes-256-cfb"  	
}
EOL

	local bindport="${1:-8388}"
	local contname="ss-astrill-$bindport"

	if ! is_range $bindport 1024 49151; then
		log_r "port range invalid" 
		exit 1
	fi	

	local contid=$(cont_id $contname)

	if [ -z $contid ]; then
		docker run -it --privileged \
			-e DISPLAY=$DISPLAY \
			-p "$bindport:8388" \
			-p "$bindport:8388/udp" \
			-v /tmp/.X11-unix:/tmp/.X11-unix \
			-v $HOME/.Xauthority:/home/$USERNAME/.Xauthority \
			-v /tmp/dnsforwarder.conf:/etc/dnsforwarder.conf \
			-v /tmp/ssserver.json:/etc/shadowsocks-libev/ssserver.json \
			-v /tmp/sstunnel.json:/etc/shadowsocks-libev/sstunnel.json \
			--hostname $(hostname) \
			--name "$contname" $astrill_image
		exit 0
	fi

	if cont_running $contname; then
		echo 'container is running'
		docker exec -it --user root "$contid" /bin/bash
		exit 0
	fi	

	docker start -ai "$contid"
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


