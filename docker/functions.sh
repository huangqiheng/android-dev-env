#!/bin/dash

init_bashrc()
{
	local inputScript="$(cat /dev/stdin)"

	if [ -f $1/.bashrc ]; then
		return
	fi

	echo "$inputScript" > $1/.bashrc
}

gen_bashrc()
{
	empty_exit $1 'code begin mark'
	empty_exit $2 'code end mark'
	empty_exit $3 'home directory'

	local out_file="$3/.bashrc"

	if [ "x$4" = 'xf' ]; then
		rm -f $out_file
	else
		if [ -f $out_file ]; then
			log_g "bashrc is ready."
			return
		fi
	fi

	local begincode="$1"
	local endcode="$2"

	cp /etc/skel/.bashrc  "$out_file"
	echo "$(sed -n '/^\s*'$begincode'/,/^\s*'$endcode'/p' $EXEC_SCRIPT)" >> $out_file

	if [ $(whoami) = 'root' ]; then
		chownUser $3
	fi
}

gen_entrycode()
{
	local begincode="$1"
	local endcode="$2"
	local out_file="/tmp/entry-$EXEC_NAME.sh"
	local src="$(sed -n '/^\s*'$begincode'/,/^\s*'$endcode'/p' $EXEC_SCRIPT)"

	if [ -f $out_file ]; then
		local dst="$(sed -n '/^\s*'$begincode'/,/^\s*'$endcode'/p' $out_file)"

		if [ "$src" = "$dst" ]; then
			echo $out_file
			echo "${Green}entrycode is ready.${Color_Off}" >&2
			return
		fi
	fi

	cat > $out_file <<-EOL
	#!/bin/dash
	waitfor_die() { sleep infinity & CLD=\$!;[ -n "\$1" ] && trap "\${1};kill -9 \$CLD" 1 2 9 15;wait "\$CLD"; }
EOL

	echo "$src" >> $out_file
	chmod a+x $out_file 
	echo $out_file

	if [ $(whoami) = 'root' ]; then
		chown $RUN_USER:$RUN_USER $out_file
	fi
}

image_ratpoison()
{
	docker_home "$1" #return var: SubHome SubName

	export IMG_RATPOISON='imgbase-ratpoison'

	build_image $IMG_RATPOISON <<-EOL
	FROM ubuntu:18.04

	RUN groupadd -r user && \ 
	    useradd -m -s /bin/bash -d /home/user -r -u 1000 -g user -G audio,video user

	ENV DEBIAN_FRONTEND=noninteractive \
	    HOME=/home/user \
	    SERVERNUM=1 \
	    TERM=xterm \
	    LANG=zh_CN.UTF-8 \
	    LANGUAGE=zh_CN:zh:en_US:en \
	    RESOLUTION=800x600 \
	    VNC_PASSWD=vncpassword

	RUN apt update -y \
	    && apt install -y --no-install-recommends \
	    language-pack-zh-hans ttf-wqy-zenhei fonts-wqy-zenhei \
	    gosu xdotool xterm git python-numpy \
	    && apt install -y \
	    xvfb xserver-xorg-video-dummy x11vnc xinit ratpoison \
	    && git clone git://github.com/novnc/noVNC.git /noVNC \
	    && git clone --branch v0.9.0 git://github.com/novnc/websockify.git /noVNC/utils/websockify \
	    && ln -sf /noVNC/vnc.html /noVNC/index.html \
	    && apt autoremove -y git && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*
EOL
}

IMG_BASE='desktop-base'

docker_desktop()
{
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_BASE <<-EOL
	FROM ubuntu:18.04

	ENV NO_AT_BRIDGE=1 \
	    LANG=zh_CN.UTF-8 \
	    LANGUAGE=zh_CN:zh \
	    LC_ALL=zh_CN.UTF-8 \
	    DEBIAN_FRONTEND=noninteractive

	RUN apt update -y && apt install -y \
	    dbus-x11 \
	    software-properties-common \
	    language-pack-zh-hans \
	    tzdata \
	    libgl1-mesa-dri \
	    libgl1-mesa-glx \
	    alsa-utils \
	    pulseaudio \
	    libasound2 libpulse0 \
	    ttf-wqy-zenhei \
	    ttf-wqy-microhei \
	    fonts-open-sans \
	    fonts-wqy-zenhei \
	    fonts-wqy-microhei \
	    fontconfig \
	    && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*
EOL
	chownUser "$SubHome"
}
