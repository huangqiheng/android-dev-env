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
	    && apt-get install -y vim net-tools psmisc iproute2 nscd dnsutils \\
	    && apt-get install -y openssl libssl-dev \\
	    && apt-get install -y rng-tools shadowsocks-libev \\
	    && apt-get install -y libgtk2.0-0 libcanberra-gtk-module \\
	    && apt-get install -y gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \\
	    && apt-get install -y gnome-themes-standard \\
	    && useradd -m -p \$(openssl passwd -1 $PASSWORD) -s /bin/bash $USERNAME \\
	    && dpkg -i /root/astrill-setup-linux64.deb \\
	    && ln -sf /usr/local/Astrill/astrill /usr/local/bin/astrill \\
	    && apt-get autoremove
	RUN echo '#!/bin/dash' > /usr/local/bin/ss-astrill \\
	    && echo 'ss-server &' >> /usr/local/bin/ss-astrill \\
	    && echo 'astrill' >> /usr/local/bin/ss-astrill \\
	    && chmod a+x /usr/local/bin/ss-astrill
	USER $USERNAME
	ENV HOME /home/$USERNAME
	CMD ss-astrill
EOL

	cat > /tmp/shadowsocks.conf <<-EOL
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
			-v /tmp/shadowsocks.conf:/etc/shadowsocks-libev/config.json \
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


