#!/bin/dash

. $(f='basic_mini.sh'; while [ ! -f $f ]; do f="../$f"; done; echo $(readlink -f $f))

IFAC="${IFAC:-'wlan0'}"
SSID="${SSID:-'JustOnlyHotspot'}"
PASS="${PASS:-'DontConnectMe'}"
GATE="${GATE:-'192.168.123.1'}"

main () 
{
	SUBNET="${GATE%.*}.0/24"
	HWMODE="${HWMODE:-'g'}"
	CHANNEL="${CHANNEL:-'6'}"

	#----------------------------------------------------- conditions ---
	check_privil
	check_apmode $IFAC

	nmcli device set "$IFAC" managed no
	systemctl restart NetworkManager

	#--------------------------------------------------- hostapd ---

	conn_state=$(nmcli device show $IFAC | head -10 | grep STATE | awk '{print $2}')
	if [ "$conn_state" = '100' ]; then
		nmcli device disconnect $IFAC
	fi
	rfkill unblock wlan
	sleep 1

	#------ set gateway ------
	log_y 'start set gateway'
	ip addr flush dev $IFAC
	ip link set $IFAC up
	ip addr add $GATE/24 dev $IFAC

	#------ setup hotspot ------
	log_y "starting hostapd: $SSID @ $IFAC"

	cat > /tmp/hostapd.conf <<-EOF
	interface=$IFAC
	driver=nl80211

	ssid=$SSID
	hw_mode=$HWMODE
	channel=$CHANNEL
	#ieee80211n=1
	#ieee80211d=1
	#ieee80211ac=1
	country_code=US
	#ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
	macaddr_acl=0
	wmm_enabled=0
	ignore_broadcast_ssid=0
	auth_algs=1
	wpa=2
	wpa_key_mgmt=WPA-PSK
	wpa_passphrase=$PASS
	rsn_pairwise=CCMP
EOF
	killall hostapd
	hostapd /tmp/hostapd.conf &
	PIDS2KILL="$PIDS2KILL $!"

	#--------------------------------------------------------- dns -----
	log_y "starting dnsmasq dhcp: $SUBNET"

	#------ rebuild dns ------
	systemctl stop systemd-resolved
	systemctl disable systemd-resolved
	cat > /etc/resolv.conf <<-EOF
	nameserver 114.114.114.114
	nameserver 8.8.8.8
EOF

	#--------------------------------------------------------- dhcp -----

	if ! cmd_exists dhcpserver; then
		local srczip=
		cd $EXEC_DIR
		if [ -f dhcpserver-master.zip ]; then
			srczip=$EXEC_DIR/dhcpserver-master.zip
		else
			if [ -f ../data/dhcpserver-master.zip ]; then
				srczip=$(dirname $EXEC_DIR)/data/dhcpserver-master.zip
			fi
		fi
		if [ "X$srczip" = 'X' ]; then
			log_y 'Not found dhcpserver-master.zip'
			exit 
		fi
		unzip -o -d /tmp dhcpserver-master.zip
		cd /tmp/dhcpserver-master
		make 
		cp ./dhcpserver /usr/local/bin
	fi

	killall dhcpserver

	./dhcpserver                                    \
	    -o ROUTER,$GATE				\
	    -o SUBNET_MASK,255.255.255.0                \
	    -o IP_ADDRESS_LEASE_TIME,3600	        \
	    -o RENEWAL_T1_TIME_VALUE,1800	    	\
	    -o REBINDING_T2_TIME_VALUE,3000		\
	    -o BROADCAST_ADDRESS,${GATE%.*}.255         \
	    -o DOMAIN_NAME,'armbian.com'                \
	    -o DOMAIN_NAME_SERVER,114.114.114.114       \
	    -a ${GATE%.*}.100,${GATE%.*}.200            \
	    -p 30		                        \
	    -d $IFAC					\
	    $GATE

	PIDS2KILL="$PIDS2KILL $!"

	#----------------------------------------------------------- nat ----

	WAN_IFACE=$(route | grep '^default' |  head -1 | grep -o '[^ ]*$')
	WAN_GATE=$(route -n | grep $WAN_IFACE | grep UG | head -1 | awk '{ print $2}')

	log_y "enable internet access: $IFAC -> $WAN_IFACE -> $WAN_GATE"

	iptables-save > /tmp/hostap-iptables.rules

	local wannet_iface=$WAN_IFACE 	# like eth0
	local subnet_iface=$IFAC 	# like wlan0
	local subnet_range=$SUBNET 	# like 192.168.234.0/24
	iptables -t nat -D POSTROUTING -s $subnet_range -o $wannet_iface -j MASQUERADE > /dev/null 2>&1 || true
	iptables -t nat -A POSTROUTING -s $subnet_range -o $wannet_iface -j MASQUERADE
	iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 
	iptables -D FORWARD -i "$subnet_iface" -o "$wannet_iface" -j ACCEPT > /dev/null 2>&1 || true
	iptables -A FORWARD -i "$subnet_iface" -o "$wannet_iface" -j ACCEPT

	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv6.conf.all.forwarding=1

	fun_exists 'on_ap_ready' && on_ap_ready

	#------------------------------------------------------ clean up ----
	log_y 'access point is ready'

	waitfor_die "$(cat <<-EOL
	iptables-restore < /tmp/hostap-iptables.rules
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv6.conf.all.forwarding=0
	kill $PIDS2KILL >/dev/null 2>&1
	ip addr flush dev $IFAC
EOL
)"
	return 0
}

on_ap_ready()
{

}

main "$@"; exit $?
