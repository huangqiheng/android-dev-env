THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	check_update
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

nginx_service ()
{
	if [ -f "/lib/systemd/system/nginx.service" ]; then
		log 'nginx.service is exists.'
		return
	fi

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

apt_prepare_tools () 
{
	apt install -y build-essential git
}

build_nginx ()
{
	if command_exists /usr/local/nginx/sbin/nginx ; then
		log 'nginx has been installed'
		#return
	fi

	apt install -y libpcre3-dev libssl-dev
	apt install -y libavcodec-dev libavformat-dev libavfilter-dev
	apt install -y libexpat1-dev


	cd $THIS_DIR
	mkdir -p temp && cd temp

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
		--add-module=../nginx-http-auth-digest \
		--add-module=../nginx-dav-ext-module \
		--add-module=../nginx-vod-module

	make
	make install
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
