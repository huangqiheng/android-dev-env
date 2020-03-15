#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS="$EXEC_NAME-apps"

docker_entry()
{
	gen_entrycode '###ENTRY_BEGIN###' '###ENTRY_END###'; return
	###ENTRY_BEGIN###

	set -e

	export DISPLAY=:1
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


	echo "------------------ start started ------------------"
	#/usr/bin/startx $(which ratpoison) -- $DISPLAY vt2  > $HOME/wm.log &
	#/usr/bin/startx -- $DISPLAY vt2
	#runuser user -c 'xinit $(which ratpoison)'
	chown user:user $HOME -R
	startx xterm
	sleep 2

	#vncserver -kill $DISPLAY || rm -rfv /tmp/.X*-lock /tmp/.X11-unix
	vncserver -kill $DISPLAY || rm -rfv /tmp/.X*-lock 
	vncserver $DISPLAY -fg -noxstartup -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION &

	# run novnc
	$NO_VNC_HOME/utils/launch.sh --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT &

	###ENTRY_END###
}

docker_bashrc()
{
	gen_bashrc '###BASHRC_BEGIN###' '###BASHRC_END###' $1; return
	###BASHRC_BEGIN###

	###BASHRC_END###
}

main() 
{
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM ubuntu:18.04
	COPY ./astrill-setup-linux64.deb /root
	COPY ./noVNC-1.0.0.tar.gz /root
	COPY ./websockify-0.6.1.tar.gz /root
	COPY ./tigervnc-1.8.0.x86_64.tar.gz /root

	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video,tty user

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
	    gosu supervisor gnupg-agent \
	    dbus-x11 xserver-xorg-core xfonts-base xinit x11-xserver-utils ratpoison xorgxrdp xterm \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN apt update -y && apt install -y --no-install-recommends \
	    wget net-tools bzip2 python-numpy \
	    && mkdir -p \$NO_VNC_HOME/utils/websockify \
	    && tar -xzf /root/tigervnc-1.8.0.x86_64.tar.gz --strip 1 -C / \
	    && tar -xzf /root/noVNC-1.0.0.tar.gz --strip 1 -C \$NO_VNC_HOME \
	    && tar -xzf /root/websockify-0.6.1.tar.gz --strip 1 -C \$NO_VNC_HOME/utils/websockify \
	    && chmod +x -v \$NO_VNC_HOME/utils/*.sh \
	    && ln -s \$NO_VNC_HOME/vnc_lite.html \$NO_VNC_HOME/index.html \
	    && apt autoremove -y && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	ENTRYPOINT [ "/usr/bin/entrypoint" ]
EOL

	docker_bashrc $SubHome

	#docker run -it --rm \
	docker run -it --rm --privileged \
		--net host \
		-v $SubHome:/home/user \
		-v $(docker_entry):/usr/bin/entrypoint \
		-v /etc/localtime:/etc/localtime:ro \
		-p 5901:5901 -p 6901:6901 \
		--name "$EXEC_NAME-$SubName" $IMG_APPS

		#-u 0 \
		#--entrypoint "bash" \

	self_cmdline
}

main_entry $@
