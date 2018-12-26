#!/bin/dash

. $(dirname $(readlink -f $0))/basic_mini.sh

AP_IFACE="${AP_IFACE:-wlan0}"
AP_SUBNET="${AP_SUBNET:-10.0.0.1/24}"
INTERNET_IFACE="${INTERNET_IFACE:-eth0}"
SSID="${SSID:-HighDangerousHotspot}"
PASSWORD="${PASSWORD:-DoNotConnectToMe}"
CAPTURE_FILE="${CAPTURE_FILE:-/home/http-traffic.cap}"

main () 
{
	check_update
	ifconfig "$AP_IFACE" "$AP_SUBNET"

	setup_dbus
	setup_dnsmasq
	setup_hostapd
	setup_iptables

	trap on_exit_handler TERM KILL

	run_mitmproxy
	wait_until_die
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

	mitmdump --mode transparent --rawtcp --listen-port 1337 --save-stream-file "$CAPTURE_FILE" "$FILTER" &
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
	sysctl -w net.ipv4.conf.all.send_redirects=0

	iptables -F
	iptables -t nat -F
	iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
	iptables -A FORWARD -i "$INTERNET_IFACE" -o "$AP_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 
	iptables -A FORWARD -i "$AP_IFACE" -o "$INTERNET_IFACE" -j ACCEPT
	iptables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337
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
	sed -ri "s|^[;# ]*DAEMON_CONF[ ]*=.*|DAEMON_CONF=/etc/hostapd/hostapd.conf|" /etc/default/hostapd

	/etc/init.d/hostapd restart
}

setup_dnsmasq()
{
	check_apt dnsmasq

	cat > /etc/dnsmasq.d/dnsmasq.conf <<-EOF
	interface=$AP_IFACE
	listen-address=${AP_SUBNET%/*}
	bind-interfaces
	server=8.8.8.8
	domain-needed
	bogus-priv
	dhcp-range=${AP_SUBNET%.*}.50,${AP_SUBNET%.*}.150,12h
EOF
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

	local mac=$(iface_to_mac $AP_IFACE)
	set_ini '/etc/NetworkManager/NetworkManager.conf'
	set_ini 'keyfile' 'unmanaged-devices' "mac:$mac"
	set_ini 'device' 'wifi.scan-rand-mac-address' 'no'

	systemctl restart NetworkManager
	exit 0
}

maintain()
{
	[ "$1" = 'release' ] && release_host_wifi  $2
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	local thisFile=$(basename $THIS_SCRIPT)
	cat <<- EOL
	AP_IFACE=wlan0 INTERNET_IFACE=eth0 sh $thisFile ;; run in docker
	AP_IFACE=wlan0 sudo sh $thisFile release	;; run in host
EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
