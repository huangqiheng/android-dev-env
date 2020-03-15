#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS="$EXEC_NAME-apps"

docker_bashrc()
{
	gen_bashrc '###BASHRC_BEGIN###' '###BASHRC_END###' $1; return
	###BASHRC_BEGIN###

	###BASHRC_END###
}

docker_entry()
{
	gen_entrycode '###ENTRY_BEGIN###' '###ENTRY_END###'; return
	###ENTRY_BEGIN###
	set -e
	cd $HOME

	cat > $HOME/ssserver.json <<-EOL
{
	"server":"0.0.0.0",
	"server_port":16666,
	"mode":"tcp_and_udp",
        "password":"${SSPASSWD}",
	"timeout":600,
	"method":"xchacha20-ietf-poly1305"  	
}
EOL

	cat > $HOME/sstunnel.json <<-EOL
{
        "server":"${SSSERVER}",
        "password":"${SSPASSWD}",
        "server_port":16666,
        "mode":"tcp_and_udp",
	"local_address": "127.0.0.1",
	"local_port":53,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL

	if [ ! "X$SSSERVER" = 'X' ]; then
		gosu user ss-tunnel -v -c $HOME/sstunnel.json -L 8.8.8.8:53 &
		sleep 1 
		gosu user ss-server -v -d 127.0.0.1:53 -c $HOME/ssserver.json &
		sleep 1 
	fi

	#----------------------------------------#
	#             ratpoison base             #
	#----------------------------------------#

	# Init ratpoison 
	ratrc=$HOME/.ratpoisonrc
	if [ ! -f $ratrc ]; then
		gosu user echo "escape C-b" > $ratrc
		gosu user echo "exec /usr/local/Astrill/astrill" >> $ratrc
	fi

	# X Server
	cat > /etc/X11/xorg.conf <<EOF
	Section "Device"
	    Identifier  "Dummy"
	    Driver      "dummy"
	    VideoRam    256000
	    Option      "IgnoreEDID"    "true"
	    Option      "NoDDC" "true"
	EndSection

	Section "Monitor"
	    Identifier  "Monitor"
	    HorizSync   15.0-100.0
	    VertRefresh 15.0-200.0
	EndSection

	Section "Screen"
	    Identifier  "Screen"
	    Monitor     "Monitor"
	    Device      "Dummy"
	    DefaultDepth    24
	    SubSection  "Display"
		Depth   24
		Modes   "$RESOLUTION"
	    EndSubSection
	EndSection
EOF
	gosu user startx -- :$SERVERNUM & 
	sleep 3

	# VNC Server
	opts="-xkb -forever -noxrecord -noxfixes -noxdamage"
	if [ -z $VNC_PASSWD ]; then
		gosu user x11vnc -display :$SERVERNUM $opts &
	else
		gosu user mkdir -p $HOME/.x11vnc
		gosu user x11vnc -storepasswd $VNC_PASSWD $HOME/.x11vnc/passwd
		gosu user x11vnc -display :$SERVERNUM $opts -rfbauth $HOME/.x11vnc/passwd &
	fi

	# NoVNC
	cert_file=$HOME/noVNC.pem
	if [ ! -f $cert_file ]; then
		gosu user openssl req -new -x509 -days 36500 -nodes -batch -out $cert_file -keyout $cert_file
	fi	

	gosu user /noVNC/utils/launch.sh --listen 6080 --vnc localhost:5900 --cert $cert_file
	#gosu user /noVNC/utils/launch.sh --listen 6080 --vnc localhost:5900 --cert $cert_file --ssl-only
	###ENTRY_END###
}

main() 
{
	image_ratpoison "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM $IMG_RATPOISON
	COPY ./astrill-setup-linux64.deb /root

	RUN apt update -y && apt install -y --no-install-recommends \
	    openssl libssl-dev \
	    rng-tools shadowsocks-libev \
	    vim net-tools psmisc iproute2 nscd dnsutils \
	    libgtk2.0-0 libcanberra-gtk-module \
	    gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \
	    gnome-themes-standard \
	    && service shadowsocks-libev stop \
	    && dpkg -i /root/astrill-setup-linux64.deb \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	WORKDIR \$HOME
	ENTRYPOINT [ "/usr/bin/entrypoint" ]
EOL

	docker_bashrc $SubHome

	# docker run -it --rm \
	docker run -it --rm --privileged \
		-e SSSERVER=$SSSERVER \
		-e SSPASSWD=$SSPASSWD \
		-e VNC_PASSWD=$VNCPASS \
		-v $SubHome:/home/user \
		-v /etc/localtime:/etc/localtime:ro \
		-v $(docker_entry):/usr/bin/entrypoint \
		-p 6080:6080 \
		-p 16666:16666 \
		--name "$EXEC_NAME-$SubName" $IMG_APPS

	self_cmdline
}

main_entry $@
