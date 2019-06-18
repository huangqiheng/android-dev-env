#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

SSCONF=/etc/ss-libev/ss-server.config
SSPORT=16666

main() 
{
	if [ "X$1" != 'X' ]; then
		SSPASSWORD="$1"
	fi

	ssredir_from_source
	server_config
	service_config
}

ssredir_from_source() 
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

	log_y 'SS Ready: ss-local ss-tunnel ss-server ss-manager ss-redir'
}


hit_once()
{
	if [ "X$__HITONCE_FLAG" = 'X' ]; then
		__HITONCE_FLAG=true
		apt install -y --no-install-recommends \
		  build-essential autoconf automake \
		  libtool libpcre3-dev asciidoc xmlto \
		  gettext libev-dev libudns-dev libc-ares-dev
	fi
}

service_config()
{
	cat > /lib/systemd/system/ssserver.service <<-EOL
	[Unit]
	Description=Service For Shadowsocks server
	After=network.target

	[Service]
	Type=simple
	CapabilityBoundingSet=CAP_NET_BIND_SERVICE
	AmbientCapabilities=CAP_NET_BIND_SERVICE
	ExecStart=/usr/local/bin/ss-server -c ${SSCONF}

	[Install]
	WantedBy=multi-user.target
EOL
	systemctl enable ssserver
	systemctl start ssserver
	systemctl status ssserver

	log_y 'To stop service: systemctl stop ssserver'
}

server_config()
{
	check_apt jq

	mkdir -p $(dirname "$SSCONF")

	if [ -z $SSPASSWORD ]; then
		if [ ! -f "$SSCONF" ]; then
			read -p 'Input Shadowsocks PASSWORD: ' SSPASSWORD
		else
			SSPASSWORD=$(cat "$SSCONF" | jq -c '.password' | tr -d '"')
			if [ "X$SSPASSWORD" = 'X' ]; then
				read -p 'Input Shadowsocks PASSWORD: ' SSPASSWORD
			fi
		fi
	fi

	cat > "$SSCONF" <<EOL
{
        "server": "0.0.0.0",
        "mode": "tcp_and_udp",
        "server_port": ${SSPORT},
        "password": "${SSPASSWORD}",
        "method": "xchacha20-ietf-poly1305",
        "timeout": 300,
        "fast_open": false
}
EOL
	cat "$SSCONF"
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
