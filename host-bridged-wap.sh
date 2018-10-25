#!/bin/bash

GATEWAY_IFACE='eno1'
WIRELESS_IFACE='wlp2s0'
WAP_ESSID='and_wifi_hotspot'
WAP_PASSD='password'


THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	apt_update_upgrade
	base_services
	setup_network
	setup_dhcp_server

	monitoring_darkstat
	monitoring_saidar
}

setup_network()
{
	if grep -q "wireless-essid" /etc/network/interfaces; then
		log 'wireless has been config?'
		return
	fi

	apt install bridge-utils

	cat >/etc/network/interfaces <<EOL
auto lo
iface lo inet loopback

auto ${GATEWAY_IFACE}
iface ${GATEWAY_IFACE} inet dhcp
pre-up iptables-restore < /etc/iptables.rules
post-down iptables-save > /etc/iptables.rules

auto ${WIRELESS_IFACE}
iface ${WIRELESS_IFACE} inet manual
wireless-mode master
wireless-essid ${WAP_ESSID}
wireless-key ${WAP_PASSD}

auto br0
iface br0 inet static
    address 10.1.1.1
    network 10.1.1.0
    netmask 255.255.255.0
    broadcast 10.1.1.255
    bridge-ports ${GATEWAY_IFACE} ${WIRELESS_IFACE}
EOL

	iptables -t nat -A POSTROUTING -s 10.1.1.0/24 -o ${GATEWAY_IFACE} -j MASQUERADE
	iptables -A FORWARD -s 10.1.1.0/24 -o ${GATEWAY_IFACE} -j ACCEPT
	iptables -A FORWARD -d 10.1.1.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -i ${GATEWAY_IFACE} -j ACCEPT

	#iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 80 -j LOG --log-prefix "NEW_HTTP_CONN: "

	sh -c "iptables-save > /etc/iptables.rules"
	sysctl_conf net.ipv4.ip_forward 1
	echo 1 > /proc/sys/net/ipv4/ip_forward

}

setup_dhcp_server()
{
	apt install isc-dhcp-server

	if grep -q "subnet 10.1.1.0" /etc/dhcp/dhcpd.conf; then
		log 'dhcp server has been config?'
		return
	fi

	cat >> /etc/dhcp/dhcpd.conf <<EOL
subnet 10.1.1.0 netmask 255.255.255.0 {
	option domain-name-servers 10.1.1.1;
	max-lease-time 7200;
	default-lease-time 600;
	range 10.1.1.100 10.1.1.200;
	option subnet-mask 255.255.255.0;
	option broadcast-address 10.1.1.255;
	option routers 10.1.1.1;
}
EOL
	dhcp_conf INTERFACES "br0"
}

monitoring_darkstat()
{
	apt install -y darkstat

	key="START_DARKSTAT"; val="yes"
	sed -ri "s/^[#]?${key}[ ]*=.*/${key}=${val}/" /etc/darkstat/init.cfg

	key="INTERFACE"; val="-i eth1"
	sed -ri "s/^[#]?${key}[ ]*=.*/${key}=\"${val}\"/" /etc/darkstat/init.cfg

	key="PORT"; val="-p 8888"
	sed -ri "s/^[#]?${key}[ ]*=.*/${key}=\"${val}\"/" /etc/darkstat/init.cfg
}

monitoring_saidar()
{
	apt install -y saidar
}

sysctl_conf() 
{
	sed -ri "s/^[#]?${1}[ ]*=.*/${1}=${2}/" /etc/sysctl.conf
}

dhcp_conf() 
{
	sed -ri "s/^[#]?${1}[ ]*=.*/${1}=\"${2}\"/" /etc/default/isc-dhcp-server
}

base_services()
{
	tasksel install openssh-server dns-server
}

apt_update_upgrade()
{
	local input=864000
	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	if [ $diff_time -gt $input ]; then
		apt update -y && apt upgrade -y
	fi 
}

main "$@"; exit $?
