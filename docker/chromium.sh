#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
	xhost +local:root >/dev/null

	mkdir -p /tmp/chrome
	cd /tmp/chrome
	[ ! -f chrome.json ] && \
		wget https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json -O chrome.json
	chownUser /tmp/chrome

	docker run --rm -it \
		--net host \
		--cpuset-cpus 0 \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-e DISPLAY=unix$DISPLAY \
		-v $HOME/Downloads:/home/chromium/Downloads \
		--security-opt seccomp=/tmp/chrome/chrome.json \
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
		-v /run/user/1000/bus:/run/user/1000/bus \
		-v /run/udev/data:/run/udev/data \
		-e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
		-e MESA_GLSL_CACHE_DISABLE=true \
		--device /dev/snd \
		-v /dev/shm:/dev/shm \
		--name chromium \
		jess/chromium
}


main_entry $@
