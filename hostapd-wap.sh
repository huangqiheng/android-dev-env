#!/bin/bash

GATEWAY_IFACE='eno1'
WIRELESS_IFACE='wlp2s0'
DRIVER_NAME='nl80211'
WAP_ESSID='and_dell9020_hotspot'
WAP_PASSD='password'

THIS_DIR=`dirname $(readlink -f $0)`

main() 
{
	check_update
	check_root_privileges
	check_support_ap
	setup_dhcp_server
	setup_wlan_static_ip
	setup_hostapd
	setup_iptables_nat
}

setup_hostapd()
{
	if apt_need hostapd; then
 		apt install -y hostapd
	fi

	hostapd_ori=/usr/share/doc/hostapd/examples/hostapd.conf
	hostapd_conf=/etc/hostapd/hostapd.conf

	if [ ! -f $hostapd_ori ]; then
		gunzip ${hostapd_ori}.gz
	fi

	if [ ! -f $hostapd_conf ]; then
		cp $hostapd_ori $hostapd_conf
	fi

	if [ -z $DRIVER_NAME ]; then
		get_driver_depends
	fi

	if [ -z "$WIRELESS_IFACE" ]; then
		get_wifi_interface
	fi

	if [ -z $DRIVER_NAME ]; then
		echo 'Please get the driver name by lspck and modinfo command, and fill in this script'
		exit
	fi

	set_conf $hostapd_conf
	set_conf interface $WIRELESS_IFACE
	set_conf driver $DRIVER_NAME
	set_conf country_code US
	set_conf hw_mode g
	set_conf channel 6
	set_conf macaddr_acl 0
	set_conf ignore_broadcast_ssid 0
	set_conf auth_algs 1
	set_conf wpa 3
	set_conf ssid $WAP_ESSID
	set_conf wpa_passphrase $WAP_PASSD
	set_conf wpa_key_mgmt WPA-PSK
	set_conf wpa_pairwise TKIP
	set_conf rsn_pairwise CCMP

	set_conf /etc/default/hostapd
	set_conf DAEMON_CONF "\"${hostapd_conf}\""

	set_conf /etc/init.d/hostapd
	set_conf DAEMON_CONF "${hostapd_conf}"
}


setup_iptables_nat()
{
	if apt_need iptables-persistent; then
		apt install -y iptables-persistent
	fi

	persist_rules=/etc/iptables/rules.v4

	set_conf /etc/sysctl.conf
	set_conf net.ipv4.ip_forward 1

	sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

	if grep -qE "^-A POSTROUTING -o ${GATEWAY_IFACE} -j MASQUERADE$" ${persist_rules}; then
		log 'iptables rules has been configured.'
		return
	fi

	iptables -t nat -A POSTROUTING -o ${GATEWAY_IFACE} -j MASQUERADE
	iptables -A FORWARD -i ${GATEWAY_IFACE} -o ${WIRELESS_IFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i ${WIRELESS_IFACE} -o ${GATEWAY_IFACE} -j ACCEPT

	sh -c "iptables-save > ${persist_rules}"
}

setup_wlan_static_ip()
{
	ifdown ${WIRELESS_IFACE} 2>/dev/null

	cat >/etc/network/interfaces <<EOL
auto lo
iface lo inet loopback

auto ${GATEWAY_IFACE}
iface ${GATEWAY_IFACE} inet dhcp

allow-hotplug ${WIRELESS_IFACE}
iface ${WIRELESS_IFACE} inet static
  address 192.168.42.1
  netmask 255.255.255.0
EOL

	ifconfig ${WIRELESS_IFACE} 192.168.42.1
}

setup_dhcp_server()
{
	if apt_need isc-dhcp-server; then
		apt install -y isc-dhcp-server
	fi

	set_comt /etc/dhcp/dhcpd.conf
	set_comt 'off' '#' "option domain-name \"example\.org\""
	set_comt 'off' '#' "option domain-name-servers ns1\.example\.org"
	set_comt 'off' '#' "default-lease-time"
	set_comt 'off' '#' "max-lease-time"
	set_comt 'off' '#' "authoritative"

	set_conf /etc/default/isc-dhcp-server
	set_conf INTERFACES "\"${WIRELESS_IFACE}\""

	if grep -q "subnet 192.168.42.0" /etc/dhcp/dhcpd.conf; then
		log 'dhcp server has been config'
		return
	fi

	cat >> /etc/dhcp/dhcpd.conf <<EOL
subnet 192.168.42.0 netmask 255.255.255.0 {
	range 192.168.42.100 192.168.42.200;
	option broadcast-address 192.168.42.255;
	option routers 192.168.42.1;
	default-lease-time 600;
	max-lease-time 7200;
	option domain-name "local";
	option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOL
}

__comment_file=''

set_comt()
{
	num_param=$#
	if [ $num_param -eq 1 ]; then
		__comment_file=$1
		return
	fi

	if [ -z $__comment_file ]; then
		echo 'toggle_comment(): Please set ini file first.'
		exit
	fi

	if [ "$1" = "on" ]; then
		sed -ri "s|^[${2} ]*(${3}.*)|\1|" $__comment_file
	else
		sed -ri "s|^[ ]*(${3}.*)|${2}\1|" $__comment_file
	fi
}


__ini_file=''

set_conf()
{
	num_param=$#
	if [ $num_param -eq 1 ]; then
		__ini_file=$1
		return
	fi

	if [ -z $__ini_file ]; then
		echo 'set_conf(): Please set ini file first.'
		exit
	fi

	sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" $__ini_file
}

get_driver_depends()
{
	module_names=`lspci -k | grep -A 3 -i "network" | grep -E "Kernel driver in use"`
	IFS=':'; set -- $module_names
	mod_name=`echo "$2" | xargs`
	depends=`modinfo "$mod_name" | grep 'depends'`
	IFS=' :'; set -- $depends
	DRIVER_NAME=$mod_name
}

get_wifi_interface()
{
	WIRELESS_IFACE=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
}

check_update()
{
	local input=864000
	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y && apt upgrade -y
	fi 
}

check_root_privileges()
{
	if [ $(whoami) != 'root' ]; then
	    echo "
	This script should be executed as root or with sudo:
	    sudo $0
	"
	    exit 1
	fi
}

check_support_ap()
{
	if apt_need iw; then
		apt-get -y install iw
	fi

	matched=$(iw list | sed -n -e '/* AP$/p')

	if [ "$matched" = '' ]; then
	    echo "AP is not supported by the driver of the wireless card."
	    echo "This script does not work for this driver."
	    exit 1
	fi
}

apt_need()
{
	if [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

main "$@"; exit $?
