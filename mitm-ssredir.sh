#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	#----------------------------------------------- install ss-redir

	check_apt haveged rng-tools shadowsocks-libev
	check_apt jq

	confile=/etc/shadowsocks-libev/ssredir.json
	if [ ! -f "$confile" ]; then
		cat > "$confile" <<EOL
{
	"server":"",
	"password":"",
        "mode":"tcp_and_udp",
        "server_port":16666,
        "local_address": "0.0.0.0",
        "local_port":6666,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL
		log_y "Please input SERVER and PASSWORD in ${confile}"
		exit 1
	fi

	inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
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

	ss-tproxy start

	waitfor_die "$(cat <<-EOL
	kill $PIDS2KILL >/dev/null 2>&1
	ss-tproxy stop
	ss-tproxy flush-iptables
EOL
)"
	return 0
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
