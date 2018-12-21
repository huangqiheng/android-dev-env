#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	AP_IFACE="${AP_IFACE:-wlan0}"
	INTERNET_IFACE="${INTERNET_IFACE:-eth0}"
	SSID="${SSID:-Public}"
	CAPTURE_FILE="${CAPTURE_FILE:-/root/data/http-traffic.cap}"

	ifconfig "$AP_IFACE" 10.0.0.1/24

	if [ ! -z "$PASSWORD" ]; then
	  if [ ! ${#PASSWORD} -ge 8 ] && [ ${#PASSWORD} -le 63 ]; then
	    echo "PASSWORD must be between 8 and 63 characters"
	    echo "password '$PASSWORD' has length: ${#PASSWORD}, exiting."
	    exit 1
	  fi
	  sed -i 's/#//' /etc/hostapd/hostapd.conf
	  sed -i "s/wpa_passphrase=.*/wpa_passphrase=$PASSWORD/g" /etc/hostapd/hostapd.conf
	fi

	sed -i "s/^ssid=.*/ssid=$SSID/g" /etc/hostapd/hostapd.conf
	sed -i "s/interface=.*/interface=$AP_IFACE/g" /etc/hostapd/hostapd.conf
	sed -i "s/interface=.*/interface=$AP_IFACE/g" /etc/dnsmasq.conf

	/etc/init.d/dbus start
	/etc/init.d/dnsmasq start
	/etc/init.d/hostapd start

	sysctl -w net.ipv4.ip_forward=1
	sysctl -w net.ipv4.conf.all.send_redirects=0

	iptables -F
	iptables -t nat -F
	iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
	iptables -A FORWARD -i "$INTERNET_IFACE" -o "$AP_IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT 
	iptables -A FORWARD -i "$AP_IFACE" -o "$INTERNET_IFACE" -j ACCEPT
	iptables -t nat -A PREROUTING -i "$AP_IFACE" -p tcp --dport 80 -j REDIRECT --to-port 1337

	term_handler() {
		iptables -F
		iptables -t nat -F

		/etc/init.d/dnsmasq stop
		/etc/init.d/hostapd stop
		/etc/init.d/dbus stop

		kill $MITMDUMP_PID
		kill -TERM "$CHILD" 2> /dev/null
		echo "received shutdown signal, exiting."
	}

	trap term_handler SIGTERM
	trap term_handler SIGKILL

	mitmdump --mode transparent --rawtcp --listen-port 1337 --save-stream-file "$CAPTURE_FILE" "$FILTER" &
	MITMDUMP_PID=$!
	sleep infinity &
	CHILD=$!
	wait "$CHILD"






}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
