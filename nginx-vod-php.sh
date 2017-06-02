#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update
	apt_prepare_tools
	setup_php7fpm
	build_nginx
	nginx_service
}

setup_php7fpm()
{
	if command_exists php ; then
		log 'php has been installed'
		return
	fi

	apt install -y redis-server 
	apt install -y php7.0 php7.0-dev php7.0-curl php7.0-fpm 

	cd $THIS_DIR
	mkdir -p temp && cd temp

	if [ ! -d "phpredis" ]; then
		git clone https://github.com/phpredis/phpredis.git
	fi

	cd phpredis
	git checkout php7

	phpize
	./configure
	make 
	make install

	echo "extension=redis.so" > /etc/php/7.0/mods-available/redis.ini
	ln -sf /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/20-redis.ini
	ln -sf /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/cli/conf.d/20-redis.ini

	service php7.0-fpm restart
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
	apt install -y build-essential git
}

build_nginx ()
{
	if command_exists /usr/local/nginx/sbin/nginx ; then
		log 'nginx has been installed'
		return
	fi

	apt install -y libpcre3-dev libssl-dev
	apt install -y libavcodec-dev libavformat-dev libavfilter-dev


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

command_exists() {
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
