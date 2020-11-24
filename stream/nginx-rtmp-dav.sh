#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update
	apt_install_tools

}

build_nginx ()
{
	apt install -y libpcre3-dev libssl-dev zlib1g-dev

	cd $ROOT_DIR
	mkdir -p temp && cd temp

	if [ ! -d "nginx-dav-ext-module" ]; then
		git clone https://github.com/arut/nginx-dav-ext-module.git
	fi

	if [ ! -d "nginx-http-auth-digest" ]; then
		git clone https://github.com/samizdatco/nginx-http-auth-digest.git
	fi

	if [ ! -d "nginx-rtmp-module" ]; then
		git clone https://github.com/arut/nginx-rtmp-module.git
	fi

	if [ ! -d "nginx-1.12.0" ]; then
		wget http://nginx.org/download/nginx-1.12.0.tar.gz
		tar xvzf nginx-1.12.0.tar.gz 
	fi

	cd nginx-1.12.0

	make clean
	./configure \
		--add-module=../nginx-http-auth-digest \
		--add-module=../nginx-dav-ext-module \
		--add-module=../nginx-rtmp-module \
		--with-http_dav_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_gzip_static_module \
		--with-http_ssl_module \
		--with-file-aio \
		--with-threads 

	make
	make install
}

apt_update ()
{
	local input=864000
	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y 
	fi 
}

apt_install_tools() 
{
	apt install -y build-essential git
}

main "$@"; exit $?
