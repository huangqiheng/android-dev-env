#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS="$EXEC_NAME-apps"

docker_entry()
{
	gen_entrycode '###ENTRY_BEGIN###' '###ENTRY_END###'; return
	###ENTRY_BEGIN###

	set -e
	waitfor_die() { sleep infinity & CLD=$!;[ -n "$1" ] && trap "${1};kill -9 $CLD" 1 2 9 15;wait "$CLD"; }

	USER_ID=$(id -u)
	GROUP_ID=$(id -g)
	NSS_WRAPPER_PASSWD=/tmp/passwd
	NSS_WRAPPER_GROUP=/etc/group
	cat /etc/passwd > $NSS_WRAPPER_PASSWD
	echo "default:x:${USER_ID}:${GROUP_ID}:Default Application User:${HOME}:/bin/bash" >> $NSS_WRAPPER_PASSWD
	export NSS_WRAPPER_PASSWD
	export NSS_WRAPPER_GROUP
	[ -r /usr/lib/libnss_wrapper.so ] && export LD_PRELOAD=/usr/lib/libnss_wrapper.so
	[ -r /usr/lib64/libnss_wrapper.so ] && export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
	echo "nss_wrapper location: $LD_PRELOAD"

	mkdir -p "$HOME/.vnc"
	PASSWD_PATH="$HOME/.vnc/passwd"
	echo "$VNC_PW" | vncpasswd -f > $PASSWD_PATH
	chmod 600 $PASSWD_PATH

	echo "execute utils/launch.sh"
	$NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT > $HOME/no_vnc_startup.log &
        PIDS2KILL="$PIDS2KILL $!"

	vncserver -kill $DISPLAY > $HOME/vnc_startup.log \
	    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix >> $HOME/vnc_startup.log \
	    || echo "no locks present"

	echo "---- start vncserver: VNC_COL_DEPTH=$VNC_COL_DEPTH, VNC_RESOLUTION=$VNC_RESOLUTION ---"
	vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION >> $HOME/no_vnc_startup.log &
        PIDS2KILL="$PIDS2KILL $!"
	sleep 1

	echo "------------------ xfce4 started ------------------"
	/usr/bin/startxfce4 --replace > $HOME/wm.log &
        PIDS2KILL="$PIDS2KILL $!"

	xset -dpms
	xset s noblank
	xset s off

	## log connect options
	echo "------------------ VNC environment started ------------------"
	VNC_IP=$(hostname -i)
	echo "VNCSERVER started on DISPLAY= $DISPLAY \n\t=> connect via VNC viewer with $VNC_IP:$VNC_PORT"
	echo "noVNC HTML client started:\n\t=> connect via http://$VNC_IP:$NO_VNC_PORT/?password=..."

	tail -f $HOME/*.log $HOME/.vnc/*$DISPLAY.log &
        PIDS2KILL="$PIDS2KILL $!"

        waitfor_die "$(cat <<-EOL
        kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
	###ENTRY_END###
}

docker_bashrc()
{
	gen_bashrc '###BASHRC_BEGIN###' '###BASHRC_END###' $1 f; return
	###BASHRC_BEGIN###
	/usr/local/Astrill/astrill

	###BASHRC_END###
}

main() 
{
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM ubuntu:18.04
	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video user

	ENV DISPLAY=:1 \
	    VNC_PORT=5901 \
	    NO_VNC_PORT=6901 \
	    HOME=/home/user \
	    TERM=xterm \
	    NO_VNC_HOME=/headless/noVNC \
	    DEBIAN_FRONTEND=noninteractive \
	    LANG=zh_CN.UTF-8 \
	    LANGUAGE=zh_CN:zh \
	    LC_ALL=zh_CN.UTF-8 \
	    VNC_COL_DEPTH=24 \
	    VNC_RESOLUTION=1280x1024 \
	    VNC_PW=vncpassword

	EXPOSE \$VNC_PORT \$NO_VNC_PORT

	RUN apt update -y && apt install -y --no-install-recommends \
	    language-pack-zh-hans ttf-wqy-zenhei fonts-wqy-zenhei \
	    libnss-wrapper gettext \
	    supervisor gnupg-agent \
	    dbus-x11 xserver-xorg-core xfonts-base xinit x11-xserver-utils xrdp xterm \
	    thunar xfwm4 xfce4-panel xfce4-settings xfce4-session xfce4-terminal xfdesktop4 tango-icon-theme \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN apt update -y && apt install -y --no-install-recommends \
	    wget net-tools bzip2 python-numpy \
	    && mkdir -p \$NO_VNC_HOME/utils/websockify \
	    && tar -xzf ./tigervnc-1.8.0.x86_64.tar.gz --strip 1 -C / \
	    && tar -xzf ./noVNC-1.0.0.tar.gz --strip 1 -C \$NO_VNC_HOME \
	    && tar -xzf ./websockify-0.6.1.tar.gz --strip 1 -C \$NO_VNC_HOME/utils/websockify \
	    && chmod +x -v \$NO_VNC_HOME/utils/*.sh \
	    && ln -s \$NO_VNC_HOME/vnc_lite.html \$NO_VNC_HOME/index.html \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN apt update -y && apt install -y --no-install-recommends \
	    openssl libssl-dev \
	    rng-tools shadowsocks-libev \
	    vim net-tools psmisc iproute2 nscd dnsutils \
	    libgtk2.0-0 libcanberra-gtk-module \
	    gtk2-engines gtk2-engines-pixbuf gtk2-engines-murrine \
	    gnome-themes-standard \
	    && service shadowsocks-libev stop \
	    && dpkg -i ./astrill-setup-linux64.deb \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	USER user 
	ENTRYPOINT [ "/usr/bin/entrypoint" ]
EOL

	docker_bashrc $SubHome

	docker run -it --rm --privileged \
		--net host \
		-v $SubHome:/home/user \
		-v $(docker_entry):/usr/bin/entrypoint \
		-v /etc/localtime:/etc/localtime:ro \
		--name "$EXEC_NAME-$SubName" $IMG_APPS

		#-u 0 \
		#--entrypoint "bash" \

	self_cmdline
}

main_entry $@
