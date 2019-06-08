#!/bin/dash

. $(dirname $(readlink -f $0))/basic_mini.sh


on_internet_ready()
{
	cd $THIS_DIR

	if [ "X$MITM_PROXY" = 'Xssredir' ]; then
		export SSSERVR_CONF='/etc/shadowsocks-libev/ssredir.json'
		check_ssserver_conf $SSSERVR_CONF
		sh mitm-ssredir.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	if [ "X$MITM_PROXY" = 'Xmitmproxy' ]; then
		sh mitm-mitmproxy.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	if [ "X$MITM_PROXY" = 'Xtrudy' ]; then
		sh mitm-trudy.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	if [ "X$MITM_PROXY" = 'Xredsocks' ]; then
		sh mitm-redsocks.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	if [ "X$MITM_PROXY" = 'Xredsocks2' ]; then
		sh mitm-redsocks2.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	if [ "X$MITM_PROXY" = 'Xtcpsocks' ]; then
		sh mitm-tcpsocks.sh &
		PIDS2KILL="$PIDS2KILL $!"
		return 0
	fi

	log_y 'ignore on_internet_ready'
}

main () 
{
	#----------------------------------------------------- conditions ---

	export_router_config
	check_privileged

	#-------------------------------------------------- build subnet ----
	log_y "starting dnsmasq dhcp: $SUBNET"

	#------ set gateway ------
	ip addr flush dev $LAN_IFACE
	ip link set $LAN_IFACE up
	ip addr add "$GATEWAY/24" dev $LAN_IFACE

	#------ rebuild dns ------
	setup_resolvconf

	#------ build dhcp ------
	check_apt dnsmasq
	cat > /home/dnsmasq.conf <<-EOF
	interface=$LAN_IFACE
	except-interface=$WAN_IFACE
	listen-address=$GATEWAY
	dhcp-range=${GATEWAY%.*}.100,${GATEWAY%.*}.200,12h
	bind-interfaces
	#server=114.114.114.114
	server=8.8.8.8
	domain-needed
	bogus-priv
EOF

	pkill dnsmasq
	dnsmasq -d -C /home/dnsmasq.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#------------------------------------------------------ nat mode ----
	log_y "enable internet access: $LAN_IFACE -> $WAN_IFACE"

	check_apt iptables 
	iptables-save > /home/hostap-iptables.rules

	set_nat_rules $WAN_IFACE $LAN_IFACE $SUBNET
	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv6.conf.all.forwarding=1

	fun_exists 'on_internet_ready' && on_internet_ready

	#------------------------------------------------------ clean up ----
	log_y 'router is ready'

	waitfor_die "$(cat <<-EOL
	iptables-restore < /home/hostap-iptables.rules
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv6.conf.all.forwarding=0
	kill $PIDS2KILL >/dev/null 2>&1
	ip addr flush dev $LAN_IFACE
EOL
)"
	return 0
}

set_nat_rules()
{
	local wannet_iface=$1 # like eth0
	local subnet_iface=$2 # like wlan0
	local subnet_range=$3 # like 192.168.234.0/24

	iptables -t nat -D POSTROUTING -s $subnet_range -o $wannet_iface -j MASQUERADE > /dev/null 2>&1 || true
	iptables -t nat -A POSTROUTING -s $subnet_range -o $wannet_iface -j MASQUERADE
	iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 
	iptables -D FORWARD -i "$subnet_iface" -o "$wannet_iface" -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -i "$subnet_iface" -o "$wannet_iface" -j ACCEPT
}


tcpdump_exit()
{
	tcpdump -i $LAN_IFACE
	exit 0
}

maintain()
{
	[ "$1" = 'dump' ] && tcpdump_exit
	[ "$1" = 'help' ] && show_help_exit
	[ "$1" = 'ssredir' ] && MITM_PROXY=ssredir
	[ "$1" = 'mitmproxy' ] && MITM_PROXY=mitmproxy
	[ "$1" = 'trudy' ] && MITM_PROXY=trudy
	[ "$1" = 'redsocks' ] && MITM_PROXY=redsocks
	[ "$1" = 'tcpsocks' ] && MITM_PROXY=tcpsocks
}

show_help_exit()
{
	local thisFile=$(basename $THIS_SCRIPT)
	cat <<- EOL
	LAN_IFACE=wlan0 WAN_IFACE=eth0 
	sudo sh $thisFile (tcpsocks|redsocks|trudy|mitmproxy)
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
