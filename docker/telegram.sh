#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IMG_APPS='telegram-apps'
IMG_MAIN='telegram-main'
SOCKS_PORT=2080

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
EOL
	build_image $IMG_MAIN <<-EOL
	FROM $IMG_APPS

	RUN groupadd -r user && \ 
	    useradd -m -d /home/user -r -u 1000 -g user -G audio,video user

	RUN cd /usr/bin/ && \
	    echo '#!/bin/dash' > entrypoint && \
	    echo 'cat > /home/user/config.json <<-EOF' >> entrypoint && \
	    echo '{"server":"\$SSSERVER",' >> entrypoint && \
	    echo '"server_port":\$SSPORT,' >> entrypoint && \
	    echo '"password":"\$SSPASSWORD",' >> entrypoint && \
	    echo '"mode":"tcp_and_udp",' >> entrypoint && \
	    echo '"local_address": "127.0.0.1",' >> entrypoint && \
	    echo '"local_port":$SOCKS_PORT,' >> entrypoint && \
	    echo '"method":"xchacha20-ietf-poly1305",' >> entrypoint && \
	    echo '"timeout":300,' >> entrypoint && \
	    echo '"fast_open":false}' >> entrypoint && \
	    echo 'EOF' >> entrypoint && \
	    echo '/usr/bin/ss-local -v -c /home/user/config.json &' >> entrypoint && \
	    echo '/opt/telegram/telegram' >> entrypoint && \
	    chmod a+x entrypoint

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
	CMD [ "default"]
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
		-v /run/user/1000/bus:/run/user/1000/bus \
		-v $SubHome:/home/user \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-v /run/udev/data:/run/udev/data \
		-p $SOCKS_PORT:$SOCKS_PORT \
		--device /dev/snd \
		--device /dev/dri \
		-v /etc/localtime:/etc/localtime:ro \
		--name "telegram-$SubName" $IMG_MAIN

		#-v /dev/shm:/dev/shm \

	self_cmdline
}

main_entry $@
