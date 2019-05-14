#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	#---------------------------------------------

	cd $CACHE_DIR
	export LIBSODIUM_VER=1.0.17
	if [ ! -f libsodium-$LIBSODIUM_VER.tar.gz ]; then
		if [ -f $DATA_DIR/libsodium-$LIBSODIUM_VER.tar.gz ]; then
			cp $DATA_DIR/libsodium-$LIBSODIUM_VER.tar.gz ./
		else
			wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
		fi
	fi

	if [ ! -f /usr/lib/libsodium.a ]; then 
		hit_once
		tar xvf libsodium-$LIBSODIUM_VER.tar.gz
		cd libsodium-$LIBSODIUM_VER
		./configure --prefix=/usr && make
		make install
		ldconfig
	fi

	log_y 'libsodium ready'

	#---------------------------------------------

	cd $CACHE_DIR
	export MBEDTLS_VER=2.16.0
	if [ ! -f mbedtls-$MBEDTLS_VER-gpl.tgz ]; then
		if [ -f $DATA_DIR/mbedtls-$MBEDTLS_VER-gpl.tgz ]; then
			cp $DATA_DIR/mbedtls-$MBEDTLS_VER-gpl.tgz ./
		else
			wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
		fi
	fi

	if [ ! -f /usr/lib/libmbedcrypto.a ]; then 
		hit_once
		tar xvf mbedtls-$MBEDTLS_VER-gpl.tgz
		cd mbedtls-$MBEDTLS_VER
		make SHARED=1 CFLAGS=-fPIC
		make DESTDIR=/usr install
		ldconfig
	fi

	log_y 'libmbedcrypto ready'

	#---------------------------------------------

	cd $CACHE_DIR
	if [ ! -d shadowsocks-libev ]; then
		git clone https://github.com/shadowsocks/shadowsocks-libev.git
		cd shadowsocks-libev
		git submodule update --init --recursive
	fi

	if [ ! -f /usr/local/bin/ss-redir ]; then
		hit_once
		cd shadowsocks-libev
		./autogen.sh && ./configure && make
		make install
	fi

	log_y 'ready: ss-local ss-tunnel ss-server ss-manager ss-redir'

	server_config
}


repo_install()
{
	if lsb_release -d | grep -iq 'Ubuntu 16.04'; then
		apt install software-properties-common -y
		add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
		apt update -y
		apt install -y shadowsocks-libev

		server_config
		exit 0
	fi
}


__hit_once_flag=false

hit_once()
{
	if [ "$__hit_once_flag" = 'true' ]; then
		return
	fi
	__hit_once_flag=true

	apt install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libc-ares-dev

	#apt install libmbedtls-dev libsodium-dev 
}


server_config()
{
	local host='serverip'
	local port='6666'
	local pass='password'


	mkdir -p /etc/ss-libev
	cat > /etc/ss-libev/ss-server.config <<EOL
{
        "server":"${host}",
        "mode":"tcp_and_udp",
        "server_port": "${port}",
        "password":"${pass}",
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL

	log_y 'Please edit: /etc/ss-libev/ss-server.config'
}


maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
