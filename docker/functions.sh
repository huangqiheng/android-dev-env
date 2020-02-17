#!/bin/dash

IMG_BASE='desktop-base'

docker_desktop()
{
	docker_home "$1" #return var: SubHome SubName

	build_image $IMG_BASE <<-EOL
	FROM phusion/baseimage:0.11
	CMD ["/sbin/my_init"]

	ENV NO_AT_BRIDGE=1
	ENV LANG zh_CN.UTF-8
	ENV LANGUAGE zh_CN:zh
	ENV LC_ALL zh_CN.UTF-8
	ENV DEBIAN_FRONTEND noninteractive

	RUN apt update -y && apt install -y --no-install-recommends \
	    dbus-x11 \
	    language-pack-zh-hans \
	    libasound2 \
	    libgl1-mesa-dri \
	    libgl1-mesa-glx \
	    libpulse0 \
	    ttf-wqy-zenhei \
	    ttf-wqy-microhei \
	    fonts-wqy-zenhei \
	    fonts-wqy-microhei \
	    fontconfig \
	    && apt-get clean \
	    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /root/.cache/*
EOL

}
