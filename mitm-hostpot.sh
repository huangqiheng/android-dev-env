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
	MITM_READY=true
	make_nat_router
}

on_internet_ready()
{
	if [ ! "X$MITM_READY" = Xtrue ]; then
		log_y 'ignore on_internet_ready'
		return 0
	fi

	log_y 'starting mitmproxy'

	if ! cmd_exists mitmdump; then
		cd /home
		if [ ! -f mitmproxy-4.0.4-linux.tar.gz ]; then
			check_apt wget
			wget https://snapshots.mitmproxy.org/4.0.4/mitmproxy-4.0.4-linux.tar.gz
		fi
		tar -xzvf mitmproxy-4.0.4-linux.tar.gz --directory=/usr/bin
	fi

	mitmdump --mode transparent \
		--showhost \
		--rawtcp \
		--listen-port 1337 \
		--save-stream-file "$CAPTURE_FILE" "$FILTER" &
	PIDS2KILL="$PIDS2KILL $!"
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
	log_y 'starting hostapd'

	check_apt hostapd iproute2

	cat > /home/hostapd.conf <<-EOF
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
	hostapd /home/hostapd.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#--------------------------------------------------------- dhcp -----
	log_y 'starting dnsmasq dhcp'

	check_apt dnsmasq

	cat > /home/dnsmasq.conf <<-EOF
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
	dnsmasq -d -C /home/dnsmasq.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#------------------------------------------------------ nat mode ----
	log_y 'enable internet access'

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

	fun_exists 'on_internet_ready' && on_internet_ready

	#------------------------------------------------------ clean up ----
	log_y 'access point is ready'

	waitfor_die "$(cat <<-EOL
	iptables-restore < /home/hostap-iptables.rules
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv6.conf.all.forwarding=0
	kill $PIDS2KILL >/dev/null 2>&1
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
