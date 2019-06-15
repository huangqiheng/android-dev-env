#!/bin/dash

. $(dirname $(readlink -f $0))/functions.sh

SSSERVR_CONF="${SSSERVR_CONF:-/etc/shadowsocks-libev/ssserver.json}"
SSPORT=7777

main () 
{
	#----------------------------------------------- install ss-redir

	if cmd_exists "ss-local"; then
		log_y 'ss-local is ready'
	else
		ssrdir_source
	fi

	check_apt jq

	mkdir -p /etc/shadowsocks-libev
	confile="$SSSERVR_CONF"
	if [ ! -f "$confile" ]; then
		make_ssserver_conf $confile $SSPORT
		inputServer="${SSSERVER}"
	else
		inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
		if [ "X$inputServer" = 'X' ]; then
			make_ssserver_conf $confile $SSPORT
			inputServer="${SSSERVER}"
		fi
	fi

	password=$(cat $confile | jq -c '.password' | tr -d '"')
	server_port=$(cat $confile | jq -c '.server_port')
	local_port=$(cat $confile | jq -c '.local_port')

	empty_exit "$inputServer" "inputed server in $confile"
	empty_exit "$password" "inputed password in $confile"

	ss-local -c ${confile} &
	PIDS2KILL="$PIDS2KILL $!"

	#----------------------------------------------- install polipo

	check_apt polipo

	set_conf '/etc/polipo/config'
	set_conf socksParentProxy "127.0.0.1:$SSPORT"
	set_conf socksProxyType socks5
	set_conf proxyAddress '::0'
	set_conf proxyPort 8080

	polipo -c '/etc/polipo/config' &
	PIDS2KILL="$PIDS2KILL $!"

	log_y "proxy is ready. socks:$SSPORT http:8080"
	netstat -lnp | grep 'Active Internet' -A 30 | grep 'Active UNIX' -B 30

	make_cmdline mitm-sslocal <<-EOF
	#!/bin/bash
	cd $(dirname $EXEC_SCRIPT)
	sh $(basename $EXEC_SCRIPT)
EOF
	#----------------------------------------------- wait die

	waitfor_die "$(cat <<-EOL
	kill $PIDS2KILL >/dev/null 2>&1
EOL
)"
	return 0
}

ssrdir_source()
{
	apt install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libc-ares-dev

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
