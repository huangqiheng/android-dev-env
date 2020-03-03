#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IMG_APPS='telegram-apps'
LOCAL_PORT=2080
[ $telegram_with_socks = 'true' ] || SSSERVER=''

docker_entry()
{
	gen_entrycode '###DOCKER_BEGIN###' '###DOCKER_END###'; return
	###DOCKER_BEGIN###


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

	/opt/telegram/telegram
        PIDS2KILL="$PIDS2KILL $!"

        waitfor_die "$(cat <<-EOL
        kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
	###DOCKER_END###
}

main () 
{
	docker_desktop "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM $IMG_BASE

	RUN add-apt-repository -y ppa:atareao/telegram \
	    && apt update -y && apt install -y --no-install-recommends \
	     xz-utils \
	     libgtk-3-0 \
	     libayatana-appindicator3-1 \
	     libcanberra-gtk-module \
	     libxcursor1 \
	     shadowsocks-libev \
	     falkon \
	     xdg-utils \
	     telegram \
	    && apt autoremove -y xz-utils \
	    && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video user

	USER user 

	ENV QT_DEBUG_PLUGINS=1 \
	    QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb \
	    GTK_IM_MODULE=fcitx \
	    XMODIFIERS=@im=fcitx \
	    QT_IM_MODULE=fcitx \
	    QT4_IM_MODULE=fcitx \
	    MESA_GLSL_CACHE_DISABLE=true \
	    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

	ENTRYPOINT [ "/usr/bin/entrypoint" ]
EOL

	xhost +SI:localuser:$(id -un) >/dev/null

	docker run -it --rm --privileged \
		--net host \
		--cpuset-cpus 0 \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v $HOME/.Xauthority:/home/user/.Xauthority \
		-e DISPLAY=unix$DISPLAY \
		-e SSSERVER=$SSSERVER \
		-e SSPORT=$SSPORT \
		-e SSPASSWORD=$SSPASSWORD \
		-v $(docker_entry):/usr/bin/entrypoint \
		-v /run/user/1000/bus:/run/user/1000/bus \
		-v $SubHome:/home/user \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-v /run/udev/data:/run/udev/data \
		--device /dev/snd \
		--device /dev/dri \
		-v /etc/localtime:/etc/localtime:ro \
		--name "telegram-$SubName" $IMG_APPS

		#-v /dev/shm:/dev/shm \

	self_cmdline
}

main_entry $@
