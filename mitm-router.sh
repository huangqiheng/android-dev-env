#!/bin/dash

. $(dirname $(readlink -f $0))/basic_mini.sh


export_hotspot_config()
{
	check_apt lshw

	if [ -z $WAN_IFACE ]; then
		WAN_IFACE=$(route | grep '^default' | grep -o '[^ ]*$')
	fi

	if [ -z $LAN_IFACE ]; then
		LAN_IFACE=$(lshw -quiet -c network | sed -n -e '/Ethernet interface/,+12 p' | sed -n -e '/bus info:/,+5 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g' | grep -v "$WAN_IFACE" | head -1)
		def_gateway=$(ifconfig | grep -A1 "$LAN_IFACE" | grep "inet " | head -1 | awk -F' ' '{print $2}')
	fi

	if [ -z $GATEWAY ]; then
		GATEWAY="${def_gateway:-192.168.234.1}"
	fi

	export WAN_IFACE="${WAN_IFACE}"
	export LAN_IFACE="${LAN_IFACE}"
	export GATEWAY="${GATEWAY}"
	export SUBNET="${GATEWAY%.*}.0/24"
	log_y "Config: LAN=$LAN_IFACE WAN=$WAN_IFACE GATE=$GATEWAY NET=$SUBNET"
}

on_internet_ready()
{
	cd $THIS_DIR

	if [ "X$MITM_PROXY" = 'Xssredir' ]; then
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
	export_hotspot_config
	exit

	#----------------------------------------------------- conditions ---

	if [ ! -w '/sys' ]; then
		log_r 'Not running in privileged mode.'
		exit 1
	fi

	nocmd_update hostapd
	check_apt wireless-tools haveged

	local PHY=$(cat /sys/class/net/"$LAN_IFACE"/phy80211/name)
	if ! iw phy "$PHY" info | grep -qE "^\s+\* AP$"; then
		log_r "Wireless card doesn't support AP mode."
		exit 1
	fi

	#--------------------------------------------------- release wlan ---

	log_y 'release wifi for hostapd'
	check_apt rfkill network-manager
	nmcli radio wifi off
	rfkill unblock wlan
	sleep 1

	#--------------------------------------------------- access point ---
	log_y "starting hostapd: $SSID @ $LAN_IFACE"

	check_apt hostapd iproute2

	cat > /home/hostapd.conf <<-EOF
	interface=$LAN_IFACE
	driver=nl80211
	beacon_int=25
	ssid=$SSID
	hw_mode=g
	channel=6
	ieee80211n=1
	ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
	macaddr_acl=0
	wmm_enabled=0
	ignore_broadcast_ssid=0
	auth_algs=1
	wpa=2
	wpa_key_mgmt=WPA-PSK
	wpa_passphrase=$PASSWORD
	rsn_pairwise=CCMP
EOF
	ip addr flush dev $LAN_IFACE
	ip link set $LAN_IFACE up
	ip addr add $GATEWAY/24 dev $LAN_IFACE

	pkill hostapd
	hostapd /home/hostapd.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#--------------------------------------------------------- dhcp -----
	log_y "starting dnsmasq dhcp: $SUBNET"

	systemctl stop systemd-resolved
	systemctl disable systemd-resolved
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

	iptables -t nat -D POSTROUTING -s ${SUBNET} -o ${WAN_IFACE} -j MASQUERADE > /dev/null 2>&1 || true
	iptables -t nat -A POSTROUTING -s ${SUBNET} -o ${WAN_IFACE} -j MASQUERADE
	iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 
	iptables -D FORWARD -i "$LAN_IFACE" -o "$WAN_IFACE" -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -i "$LAN_IFACE" -o "$WAN_IFACE" -j ACCEPT
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
