
#!/bin/bash

SRV_ROOT=/var/www/vodsrv


THIS_DIR=`dirname $(readlink -f $0)`
CODE_DIR=${THIS_DIR}/codes


main () 
{
	check_update
	setup_tools
	build_php7fpm
	build_nginx
	setup_website
}

setup_website()
{
	mkdir -p ${SRV_ROOT}/api
	mkdir -p ${SRV_ROOT}/mp4
	mkdir -p ${SRV_ROOT}/web

	if [ ! "$(ls -A ${SRV_ROOT}/web)" ]; then
		cp ${CODE_DIR}/404.html ${SRV_ROOT}/web/
		cp ${CODE_DIR}/50x.html ${SRV_ROOT}/web/
		cp ${CODE_DIR}/favicon.ico ${SRV_ROOT}/web/
		cp ${CODE_DIR}/crossdomain.xml ${SRV_ROOT}/web/
		cp ${CODE_DIR}/fallback.php ${SRV_ROOT}/web/
	fi

	if [ ! "$(ls -A ${SRV_ROOT}/api)" ]; then
		cp ${CODE_DIR}/mapped.php ${SRV_ROOT}/api/
	fi

	if [ ! "$(ls -A ${SRV_ROOT}/mp4)" ]; then
		cp ${CODE_DIR}/001.mp4 ${SRV_ROOT}/mp4/
		cp ${CODE_DIR}/002.mp4 ${SRV_ROOT}/mp4/
		cp ${CODE_DIR}/003.mp4 ${SRV_ROOT}/mp4/
		cp ${CODE_DIR}/004.mp4 ${SRV_ROOT}/mp4/
		cp ${CODE_DIR}/005.mp4 ${SRV_ROOT}/mp4/
		cp ${CODE_DIR}/006.mp4 ${SRV_ROOT}/mp4/
	fi
}

build_nginx ()
{
	if command_exists /usr/local/nginx/sbin/nginx ; then
		log 'nginx has been installed'
		return
	fi

	apt_ensure libpcre3-dev
	apt_ensure libssl-dev
	apt_ensure libavcodec-dev
	apt_ensure libavformat-dev
	apt_ensure libavfilter-dev
	apt_ensure libexpat1-dev

	cd $THIS_DIR
	mkdir -p temp && cd temp

	if [ ! -d "nginx-push-stream-module" ]; then
		git clone https://github.com/wandenberg/nginx-push-stream-module.git
	fi

	if [ ! -d "nginx-vod-module" ]; then
		git clone https://github.com/kaltura/nginx-vod-module.git
	fi

	if [ ! -d "nginx-dav-ext-module" ]; then
		git clone https://github.com/arut/nginx-dav-ext-module.git
	fi

	if [ ! -d "nginx-http-auth-digest" ]; then
		git clone https://github.com/samizdatco/nginx-http-auth-digest.git
	fi

	if [ ! -d "nginx-1.12.0" ]; then
		wget http://nginx.org/download/nginx-1.12.0.tar.gz
		tar xvzf nginx-1.12.0.tar.gz 
	fi

	cd nginx-1.12.0

	make clean
	./configure \
		--with-http_dav_module \
		--with-http_secure_link_module \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-file-aio \
		--with-threads \
		--with-cc-opt="-O3" \
		--with-debug \
		--add-module=../nginx-push-stream-module \
		--add-module=../nginx-http-auth-digest \
		--add-module=../nginx-dav-ext-module \
		--add-module=../nginx-vod-module

	make
	make install

	#----------------------------------#
	#      setup systemd service  	   #
	#----------------------------------#

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

	unlink /usr/local/nginx/conf/nginx.conf
	ln -s ${CODE_DIR}/nginx-jsmpeg.conf /usr/local/nginx/conf/nginx.conf

	systemctl enable nginx
	systemctl start nginx
}

build_php7fpm()
{
	if command_exists php ; then
		log 'php has been installed'
		return
	fi

	apt_ensure redis-server 
	apt_ensure php7.0
	apt_ensure php7.0-dev
	apt_ensure php7.0-curl
	apt_ensure php7.0-fpm

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

	php_ini opcache.enable 1
	php_ini opcache.enable_cli 1
	php_ini opcache.fast_shutdown 1
	#php_ini opcache.revalidate_freq 60
	php_ini opcache.revalidate_freq 0
	php_ini opcache.max_accelerated_files 4096
	php_ini opcache.interned_strings_buffer 8
	php_ini opcache.optimization_level 1
	php_ini opcache.memory_consumption 1024
	php_ini opcache.force_restart_timeout 3600

	service php7.0-fpm restart
}


php_ini()
{
	sed -ri "s/^[;]?${1}[ ]*=.*/${1}=${2}/" /etc/php/7.0/cli/phpb.ini 
}

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "
	This script should be executed as root or with sudo:
	    sudo $0
	"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	if [ $diff_time -gt 604800 ]; then
		apt update -y
	fi 

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

setup_tools() 
{
	apt_ensure build-essential
	apt_ensure git
}

apt_ensure()
{
	if apt_need "$1"; then
		apt install -y "$1"
	fi
}

apt_need()
{
	if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

command_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
