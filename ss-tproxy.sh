#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	install_tproxy
}

install_tproxy()
{
	check_apt lshw

	AP_IFACE=$(get_wifi_ifaces)
	GATEWAY=$(iface_to_ipaddr $AP_IFACE)
	SUBNET="${GATEWAY%.*}.0/24"

	if [ -z "$SUBNET" ]; then
		log_y "Can't found ap on $AP_IFACE"
		exit 1
	else 
		log_y "Found ap: $AP_IFACE $SUBNET"
	fi

	#-------------------------------------------------------

	check_apt jq

	confile=$(ps -o cmd -ax | grep [s]s-redir | awk -F' ' '{print $NF}')

	if [ -z "$confile" ]; then
		log_y "ss-redir config is not ready"
		exit 2
	fi

	inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
	server_port=$(cat $confile | jq -c '.server_port')
	local_port=$(cat $confile | jq -c '.local_port')

	if [ -z "$inputServer" ]; then
		log_y "ss-redir server is empty"
		exit 3
	fi

	#-------------------------------------------------------

	check_apt ipset iproute2 perl curl
	install_chinadns

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

	set_conf /etc/ss-tproxy/ss-tproxy.conf
	set_conf proxy_server "\(${inputServer}\)"
	set_conf proxy_dports "\'${server_port}\'"
	set_conf proxy_tcport "\'${local_port}\'"
	set_conf proxy_udport "\'${local_port}\'"
	set_conf proxy_runcmd "\'true\'"
	set_conf proxy_kilcmd "\'true\'"
	set_conf ipts_intranet "\(${SUBNET}\)"

	cp -af ss-tproxy.service /etc/systemd/system
	systemctl daemon-reload
	systemctl enable ss-tproxy
	systemctl start ss-tproxy
}

remove_tproxy()
{
	ss-tproxy stop
	ss-tproxy flush-iptables
	rm -fr /etc/ss-tproxy /usr/local/bin/ss-tproxy
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'remove' ] && remove_tproxy && exit 0
}

show_help_exit()
{
	cat << EOL
	help
	sudo sh ss-tproxy.sh remove
EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
