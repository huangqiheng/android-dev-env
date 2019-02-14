#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	#---------------------------------------------

	cd $CACHE_DIR
	export LIBSODIUM_VER=1.0.17
	if [ ! -f libsodium-$LIBSODIUM_VER.tar.gz ]; then
		wget https://download.libsodium.org/libsodium/releases/libsodium-$LIBSODIUM_VER.tar.gz
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
		wget https://tls.mbed.org/download/mbedtls-$MBEDTLS_VER-gpl.tgz
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

	log_y 'done: ss-local ss-tunnel ss-server ss-manager ss-redir'
}

__hit_once_flag=false

hit_once()
{
	if [ "$__hit_once_flag" = 'true' ]; then
		return
	fi
	__hit_once_flag=true

	apt install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libmbedtls-dev libsodium-dev libc-ares-dev
}


server_config()
{
	mkdir -p /etc/ss-libev
	cat > /etc/ss-libev/ss-server.config <<EOL
{
        "server":"${1}",
        "mode":"tcp_and_udp",
        "server_port":6666,
        "password":"${2}",
        "method":"aes-256-gcm",
        "timeout":300,
        "fast_open":false
}
EOL
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
