#!/bin/dash

. $(dirname $(readlink -f $0))/mitm-funcs.sh

export SSID="${SSID:-DangerousHotspot}"
export PASSWORD="${PASSWORD:-DontConnectMe}"

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
	check_privil
	check_apmode $LAN_IFACE

	nocmd_update hostapd
	check_apt wireless-tools haveged

	#--------------------------------------------------- release wlan ---

	log_y 'release wifi for hostapd'
	check_apt rfkill network-manager
	nmcli radio wifi off
	rfkill unblock wlan
	sleep 1

	#--------------------------------------------------- access point ---
	log_y "starting hostapd: $SSID @ $LAN_IFACE"


	check_apt bridge-utils


	#------ set gateway ------
	ip addr flush dev $LAN_IFACE
	ip link set $LAN_IFACE up
	ip addr add $GATEWAY/24 dev $LAN_IFACE

	#------ setup hotspot ------
	check_apt hostapd iproute2
	cat > /home/hostapd.conf <<-EOF
	interface=$LAN_IFACE
	driver=nl80211
	beacon_int=25
	ssid=$SSID
	hw_mode=g
	channel=6
	ieee80211n=1
	#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
	macaddr_acl=0
	wmm_enabled=0
	ignore_broadcast_ssid=0
	auth_algs=1
	wpa=2
	wpa_key_mgmt=WPA-PSK
	wpa_passphrase=$PASSWORD
	rsn_pairwise=CCMP
EOF
	pkill hostapd
	hostapd /home/hostapd.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#--------------------------------------------------------- dhcp -----
	log_y "starting dnsmasq dhcp: $SUBNET"

	#------ rebuild dns ------
	setup_resolvconf

	#------ setup dhcp ------
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
	log_y 'access point is ready'

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

release_host_wifi()
{
	check_sudo

	local mac=$(ifconfig "$LAN_IFACE" | awk '/ether/{print $2}')
	set_ini '/etc/NetworkManager/NetworkManager.conf'
	set_ini 'keyfile' 'unmanaged-devices' "mac:$mac"
	set_ini 'device' 'wifi.scan-rand-mac-address' 'no'

	systemctl restart NetworkManager
	exit 0
}

tcpdump_exit()
{
	tcpdump -i $LAN_IFACE
	exit 0
}

maintain()
{
	[ "$1" = 'dump' ] && tcpdump_exit
	[ "$1" = 'host' ] && release_host_wifi
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
