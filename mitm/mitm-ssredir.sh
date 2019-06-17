#!/bin/dash

. $(dirname $(readlink -f $0))/functions.sh

SSSERVR_CONF="${SSSERVR_CONF:-/etc/shadowsocks-libev/ssredir.json}"

main () 
{
	#----------------------------------------------- install ss-redir
	check_apt haveged rng-tools

	if cmd_exists "ss-redir"; then
		log_y 'ss-redir is ready'
	else
		ssver=$(dpkg-query --show --showformat '${Version}' shadowsocks-libev)

		if dpkg --compare-versions "$ssver" gt 3.1.2; then
			check_apt make
			check_apt shadowsocks-libev
		else
			ssrdir_source
		fi
	fi

	check_apt jq

	mkdir -p /etc/shadowsocks-libev
	confile="$SSSERVR_CONF"
	if [ ! -f "$confile" ]; then
		make_ssserver_conf $confile
		inputServer="${SSSERVER}"
	else
		inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
		if [ "X$inputServer" = 'X' ]; then
			make_ssserver_conf $confile
			inputServer="${SSSERVER}"
		fi
	fi

	password=$(cat $confile | jq -c '.password' | tr -d '"')
	server_port=$(cat $confile | jq -c '.server_port')
	local_port=$(cat $confile | jq -c '.local_port')

	empty_exit "$inputServer" "inputed server in $confile"
	empty_exit "$password" "inputed password in $confile"

	#------------------------------------------------ install ss-tproxy

	check_apt ipset iproute2 perl curl
	install_chinadns

	if ! cmd_exists 'ss-tproxy'; then
		cd $CACHE_DIR

		if [ ! -d ss-tproxy ]; then
			git clone https://github.com/zfl9/ss-tproxy
		fi

		cd ss-tproxy
		cp -af ss-tproxy /usr/local/bin
		chmod 0755 /usr/local/bin/ss-tproxy
		chown root:root /usr/local/bin/ss-tproxy

		mkdir -m 0755 -p /etc/ss-tproxy
		cp -af ss-tproxy.conf gfwlist.* chnroute.* /etc/ss-tproxy
		chmod 0644 /etc/ss-tproxy/* 
		chown -R root:root /etc/ss-tproxy
	fi

	set_conf /etc/ss-tproxy/ss-tproxy.conf
	set_conf proxy_server "\(${inputServer}\)"
	set_conf proxy_dports "\'${server_port}\'"
	set_conf proxy_tcport "\'${local_port}\'"
	set_conf proxy_udport "\'${local_port}\'"
	set_conf proxy_runcmd "\'true\'"
	set_conf proxy_kilcmd "\'true\'"
	set_conf ipts_intranet "\(${SUBNET}\)"

	ss-redir -c ${confile} &
	PIDS2KILL="$PIDS2KILL $!"

	ss-tproxy update-chnroute
	ss-tproxy update-gfwlist
	ss-tproxy start

	waitfor_die "$(cat <<-EOL
	kill $PIDS2KILL >/dev/null 2>&1
	ss-tproxy stop
	ss-tproxy flush-iptables
EOL
)"
	return 0
}

__hit_once_flag=false
hit_once()
{
	if [ "$__hit_once_flag" = 'true' ]; then
		return
	fi
	__hit_once_flag=true

	apt install -y --no-install-recommends gettext build-essential autoconf libtool libpcre3-dev asciidoc xmlto libev-dev libudns-dev automake libc-ares-dev
}

ssrdir_source()
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
}


maintain()
{
	if [ -z "$SUBNET" ]; then
		log_y 'Please call by mitm-hotspot.sh'
		exit 1
	fi

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
