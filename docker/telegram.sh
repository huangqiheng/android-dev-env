#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IMG_APPS='telegram-apps'
LOCAL_PORT=2080
[ "$telegram_with_socks" = 'true' ] || SSSERVER=''

docker_entry()
{
	gen_entrycode '###DOCKER_BEGIN###' '###DOCKER_END###'; return
	###DOCKER_BEGIN###

	mkdir -p /etc/xdg/QtProject
	cat > '/etc/xdg/QtProject/qtlogging.ini' <<-EOF
	[Rules]
	qt.qpa.xcb.xcberror=false
EOF

	if test $SSSERVER; then cat > /etc/sslocal.json <<-EOF
	{
		"server":"$SSSERVER",
		"server_port":$SSPORT,
		"password":"$SSPASSWORD",
		"mode":"tcp_and_udp",
		"local_address": "127.0.0.1",
		"local_port":$LOCAL_PORT,
		"method":"xchacha20-ietf-poly1305",
		"timeout":300,
		"fast_open":false
	}
EOF

	runuser user -c 'ss-local -v -c /etc/sslocal.json &'
        PIDS2KILL="$PIDS2KILL $!"
	fi

	runuser user -c 'telegram-desktop'
        PIDS2KILL="$PIDS2KILL $!"

        waitfor_die "$(cat <<-EOL
        kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
	###DOCKER_END###
}

# RUN add-apt-repository -y ppa:atareao/telegram && apt update -y && apt install -y \

main () 
{
	docker_desktop "$1" #return var: SubHome SubName
	set_title $SubName

	build_image $IMG_APPS <<-EOL
	FROM $IMG_BASE

	ENV QT_DEBUG_PLUGINS=1 \
	    QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb \
	    GTK_IM_MODULE=fcitx \
	    QT_IM_MODULE=fcitx \
	    QT4_IM_MODULE=fcitx \
	    XMODIFIERS=@im=fcitx \
	    DefaultIMModule=fcitx \
	    MESA_GLSL_CACHE_DISABLE=true \
	    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
	    DEBIAN_FRONTEND=noninteractive

	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video user

	RUN  apt update -y && apt install -y \
	     xz-utils \
	     libgtk-3-0 \
	     libcanberra-gtk3-module \
	     libxcursor1 \
	     libappindicator3-1 \
	     fcitx fcitx-config-gtk2 fcitx-sunpinyin fcitx-libs-dev \
	     shadowsocks-libev \
	     falkon \
	     xdg-utils \
	     telegram-desktop \
	    && apt autoremove -y xz-utils && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	ENTRYPOINT [ "/usr/bin/entrypoint" ]
EOL

	xhost +SI:localuser:$(id -un) >/dev/null

	# libayatana-appindicator3-1 \
	# --cpuset-cpus 0 \

	docker run -it --rm --privileged \
		--net host \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v $HOME/.Xauthority:/home/user/.Xauthority \
		-e DISPLAY=unix$DISPLAY \
		-e SSSERVER=$SSSERVER \
		-e SSPORT=$SSPORT \
		-e SSPASSWORD=$SSPASSWORD \
		-v $(docker_entry):/usr/bin/entrypoint \
		-v $SubHome:/home/user \
		-v $(dirname $SubHome)/Downloads:/home/user/Downloads \
		-v /run/udev/data:/run/udev/data \
		--device /dev/snd \
		--device /dev/dri \
		-v ${XDG_RUNTIME_DIR}/bus:${XDG_RUNTIME_DIR}/bus \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
		-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
		-v ~/.config/pulse/cookie:/home/user/.config/pulse/cookie \
		-e PULSE_COOKIE=/home/user/.config/pulse/cookie \
		--group-add $(getent group audio | cut -d: -f3) \
		-v /etc/localtime:/etc/localtime:ro \
		--name "telegram-$SubName" $IMG_APPS

		#-v /dev/shm:/dev/shm \

	self_cmdline
}

main_entry $@
