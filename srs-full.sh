#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update
	apt_prepare_tools
	build_srs
}

build_srs()
{
	cd $ROOT_DIR
	mkdir -p temp && cd temp

	if [ ! -d "srs" ]; then
		git clone https://github.com/ossrs/srs
	fi

	cd srs/trunk
	./configure --prefix=/opt/srs --full
	make
	make install

	cp -fv /opt/srs/etc/init.d/srs /etc/init.d/srs
	srs_config

	/etc/init.d/srs start
}

srs_config()
{
	cat >/opt/srs/conf/srs.conf <<EOL
listen              1935;
max_connections     1000;
srs_log_tank        file;
srs_log_file        ./objs/srs.log;

http_api {
        enabled         on;
        listen          1985;
        crossdomain     on;
}

http_server {
    enabled         on;
    listen          8080;
    dir             ./objs/nginx/html;
}

stats {
        network         0;
}

vhost __defaultVhost__ {
    gop_cache       off;
    queue_length    10;
    min_latency     on;
    mr {
        enabled     off;
    }
    mw_latency      100;
    tcp_nodelay     on;

    hls {
        enabled         on;
        hls_path        ./objs/nginx/html;
        hls_fragment    10;
        hls_window      60;
    }
}
EOL
}

apt_update ()
{
	if [ -z "$1" ]; then
		input=864000
	else 
		input=$1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y 
	fi 
}

apt_prepare_tools () 
{
	apt install -y build-essential git python
}

main "$@"; exit $?
