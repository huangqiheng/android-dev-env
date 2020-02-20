#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

IMG_APPS='chrome-apps'

docker_entry()
{
	local out_file="/tmp/entry-$EXEC_NAME.sh"
	echo '#!/bin/dash' > $out_file
	echo "$(sed -n '/^\s*###DOCKER_BEGIN###/,/^\s*###DOCKER_END###/p' $EXEC_SCRIPT)" >> $out_file
	chmod +x $out_file 
	echo $out_file
	return

	###DOCKER_BEGIN###

	set_tproxy(){sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" /etc/ss-tproxy/ss-tproxy.conf;}

	set_conf


	runuser user -c 'chromium-browser --user-data-dir=/data'
	###DOCKER_END###
}

main() 
{
	docker_desktop "$1" #return var: SubHome SubName

	build_image $IMG_APPS <<-EOL
	FROM $IMG_BASE

	RUN apt-get update && apt-get install -y --no-install-recommends \
	    git curl gawk perl \
	    iproute2 iptables ipset dnsmasq \
	    shadowsocks-libev \
	    chromium-browser \
	    && cd /etc && git clone https://github.com/zfl9/ss-tproxy \
	    && cd ss-tproxy && chmod +x ss-tproxy && cp -af ss-tproxy /usr/bin \
	    && apt-get purge --auto-remove -y git \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*

	RUN groupadd -r user \ 
	    && useradd -m -d /home/user -r -u 1000 -g user -G audio,video user \
	    && mkdir -p /home/user/Downloads \
	    && chown -R user:user /home/user \
	    && mkdir -p /data && chown user:user /data

	ENTRYPOINT [ "/root/entrypoint" ]
EOL

	chrome_sec # make /tmp/chrome/chrome.json

	#xhost +local:root >/dev/null
	xhost +SI:localuser:root >/dev/null

	#docker run -it --privileged \
	docker run -it --rm --privileged \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v $HOME/.Xauthority:/home/chrome/.Xauthority \
		-e DISPLAY=unix$DISPLAY \
		-e DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
		-e MESA_GLSL_CACHE_DISABLE=true \
		-v /run/user/1000/bus:/run/user/1000/bus \
		-v $HOME/Downloads:/home/chrome/Downloads \
		-v $SubHome:/data \
		-v $(docker_entry):/root/entrypoint \
		-v /dev/shm:/dev/shm \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-v /run/udev/data:/run/udev/data \
		--security-opt seccomp=$DATA_DIR/chrome.json \
		--device /dev/snd \
		--device /dev/dri \
		-v /etc/localtime:/etc/localtime:ro \
		--name "chrome-$SubName" $IMG_APPS /bin/bash
		#--name "chrome-$SubName" $IMG_ENTRY

	self_cmdline
}

#		--memory 512mb \
#		-v /dev/shm:/dev/shm \
#		-v /tmp/chrome-local.conf:/etc/fonts/local.conf \

chrome_sec()
{
	cd $DATA_DIR
	[ ! -f chrome.json ] && \
		wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O chrome.json
}

main_entry $@
