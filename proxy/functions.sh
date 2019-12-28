#!/bin/bash

new_xfb()
{
	XNEW_DIR=/var/tmp
	XNEW_DISPLAY=:10

	check_apt xvfb
	Xvfb $XNEW_DISPLAY -screen 0 1920x1080x24 -fbdir $XNEW_DIR &
}

start_openweb()
{
	check_apt x11-xserver-utils
	local openweb_image="$DOCKER_IMAGE"
	local entrycode="$2"
	local entryfile="$CACHE_DIR/openweb_entry-$(head -c 8 /dev/urandom | xxd -ps).sh"

	local bindport="${1:-8388}"
	local contname="ss-astrill-$bindport"
	if ! is_range $bindport 1024 49151; then
		log_r "port range invalid" 
		exit 1
	fi	
	local contname="ss-astrill-$bindport"
	local contid=$(cont_id $contname)

	xhost +local:root >/dev/null

	#echo "internet ip addr: $(wlan_ip)"

	#new_xfb
	HOST_DISPLAY="${XNEW_DISPLAY:-$DISPLAY}"
	HOST_X11DIR="${XNEW_DIR:-/tmp/.X11-unix}"

	if [ -z $contid ]; then
		echo "$entrycode" > $entryfile
		docker run -it --privileged \
			-e DISPLAY=$HOST_DISPLAY \
			-v $HOST_X11DIR:/tmp/.X11-unix \
			-p "$bindport:8388" \
			-p "$bindport:8388/udp" \
			-v "$entryfile:/root/entrypoint.sh" \
			--name "$contname" $openweb_image
		exit 0
	fi

	if cont_running $contname; then
		echo 'container is running'
		docker exec -it "$contid" /bin/bash
		exit 0
	fi	

	docker start -ai "$contid"
}

check_openweb_image()
{
	local openweb_image='openweb-proxychains-doh-sserver'

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

	RUN dpkg -i /root/cloudflared-stable-linux-amd64.deb \\
	    && apt-get install -y proxychains inotify-tools x11-apps

	RUN apt-get install -y libcap2-bin git gcc make automake libcurl4-gnutls-dev \\
	    && cd /root && git clone https://github.com/holmium/dnsforwarder.git \\
	    && cd dnsforwarder && ./configure && make && make install \\
	    && setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/dnsforwarder \\
	    && apt-get autoremove
EOL
}


