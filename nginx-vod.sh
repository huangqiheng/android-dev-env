#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update
	apt_dependances
	build_nginx
	nginx_service
}

nginx_service ()
{
	cat >/lib/systemd/system/nginx.service <<EOL
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOL
	systemctl enable nginx
	systemctl start nginx
}

apt_update ()
{
	local input=$1
	if [ -z "$input" ]; then
		$input=864000
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y 
	fi 
}


apt_dependances () 
{
	apt install -y build-essential git
	apt install -y libpcre3-dev libssl-dev
	apt install -y libavcodec-dev libavformat-dev libavfilter-dev
}

build_nginx ()
{
	cd $THIS_DIR
	mkdir -p temp && cd temp

	if [ ! -d "nginx-vod-module" ]; then
		git clone https://github.com/kaltura/nginx-vod-module.git
	fi

	if [ ! -d "nginx-1.12.0" ]; then
		wget http://nginx.org/download/nginx-1.12.0.tar.gz
		tar xvzf nginx-1.12.0.tar.gz 
	fi

	cd nginx-1.12.0

	make clean
	./configure \
		--with-http_ssl_module \
		--with-file-aio \
		--with-threads \
		--with-cc-opt="-O3" \
		--add-module=../nginx-vod-module

	make
	make install
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

main "$@"
exit $?
