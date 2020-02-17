#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IMG_APP='chrome-secu'
IMG_ENTRY='chrome-entry'

main () 
{
	docker_desktop "$1" #return var: SubHome SubName

	build_image $IMG_APP <<-EOL
	FROM $IMG_BASE

	RUN apt-get update && apt-get install -y --no-install-recommends \
		chromium-browser \
		&& apt-get purge --auto-remove -y \
		&& rm -rf /var/lib/apt/lists/*

	RUN groupadd -r chrome && \ 
	    useradd -r -u 1000 -g chrome -G audio,video chrome && \
	    mkdir -p /home/chrome/Downloads && \
	    chown -R chrome:chrome /home/chrome
EOL

	build_image $IMG_ENTRY <<-EOL
	FROM $IMG_APP

	RUN echo "#!/bin/dash" > /usr/bin/entrypoint && \
	    echo 'chromium-browser "\$@"' >> /usr/bin/entrypoint && \
	    chmod a+x /usr/bin/entrypoint && \
	    mkdir -p /data && chown -R chrome:chrome /data

	USER chrome

	ENTRYPOINT [ "entrypoint" ]
	CMD [ "--user-data-dir=/data"]
EOL

	#xhost +local:root >/dev/null
	xhost +SI:localuser:root >/dev/null

	mkdir -p /tmp/chrome
	cd /tmp/chrome
	[ ! -f chrome.json ] && \
		wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O chrome.json
	chownUser /tmp/chrome

	#docker run -it --privileged \
	docker run -it --rm --privileged \
		--net host \
		--cpuset-cpus 0 \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v $HOME/.Xauthority:/home/chrome/.Xauthority \
		-e DISPLAY=unix$DISPLAY \
		-e DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
		-e MESA_GLSL_CACHE_DISABLE=true \
		-v /run/user/1000/bus:/run/user/1000/bus \
		-v $HOME/Downloads:/home/chrome/Downloads \
		-v $SubHome:/data \
		-v /dev/shm:/dev/shm \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-v /run/udev/data:/run/udev/data \
		--security-opt seccomp=/tmp/chrome/chrome.json \
		--device /dev/snd \
		--device /dev/dri \
		-v /etc/localtime:/etc/localtime:ro \
		--name "chrome-$SubName" $IMG_ENTRY

	self_cmdline
}


#	mkdir -p /tmp/chrome
#	cd /tmp/chrome
#	[ ! -f chrome.json ] && \
#		wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O chrome.json
#	chownUser /tmp/chrome
#
#		--memory 512mb \
#		-v /dev/shm:/dev/shm \
#		-v /tmp/chrome-local.conf:/etc/fonts/local.conf \
#		--security-opt seccomp=/tmp/chrome/chrome.json \
#		-v $SubHome:/data \

main_entry $@
