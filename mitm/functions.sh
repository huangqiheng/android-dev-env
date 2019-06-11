#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

force_bridge_mitm()
{
	ensure_apt bridge-utils network-manager rfkill

	if [ $# -lt 2 ]; then
		log_r 'at lease two parameters'
		return 1
	fi

	if brctl show 'brmitm' >/dev/null 2>&1; then
		brctl delbr 'brmitm'
	fi

	local check_on=

	brctl addbr 'brmitm'
	for iface in $@; do
		if iw dev "$iface" info >/dev/null 2>&1; then
			if [ -z $check_on ]; then
				rfkill unblock wifi
				nmcli radio wifi on
				check_on=true
			fi
			iw dev "$iface" set 4addr on
		fi
		brctl addif 'brmitm' "$iface"
	done
	return 0
}


check_apmode()
{
	local PHY=$(cat /sys/class/net/${1}/phy80211/name)
	if ! iw phy "$PHY" info | grep -qE "^\s+\* AP$"; then
		log_r "Wireless card doesn't support AP mode."
		exit 1
	fi
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

export_router_config()
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
	log_y "Config: WAN=$WAN_IFACE LAN=$LAN_IFACE GATE=$GATEWAY NET=$SUBNET"
}


setup_resolvconf()
{
	systemctl stop systemd-resolved
	systemctl disable systemd-resolved
	check_apt resolvconf

	rm -f /etc/resolv.conf
	cat > /etc/resolv.conf <<-EOF
	nameserver 8.8.8.8
	nameserver 114.114.114.114
EOF
}

check_ssserver_conf()
{
	check_apt jq
	local confile="$1"
	mkdir -p $(dirname $confile)

	if [ ! -f "$confile" ]; then
		make_ssserver_conf $confile
		return 0
	fi

	inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
	if [ "X$inputServer" = 'X' ]; then
		make_ssserver_conf $confile
	fi

	inputPassword=$(cat $confile | jq -c '.password' | tr -d '"')
	if [ "X$inputPassword" = 'X' ]; then
		make_ssserver_conf $confile
	fi
}

make_ssserver_conf()
{
	local confile="$1"
	read -p 'Input Shadowsocks SERVER: ' SSSERVER
	read -p 'Input Shadowsocks PASSWORD: ' SSPASSWORD
	cat > "$confile" <<EOL
{
	"server":"${SSSERVER}",
	"password":"${SSPASSWORD}",
        "mode":"tcp_and_udp",
        "server_port":16666,
        "local_address": "0.0.0.0",
        "local_port":6666,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL
}


install_chinadns()
{
	if  cmd_exists 'chinadns'; then
		log_y 'chinadns is ready'
		return
	fi

	check_apt build-essential

	local chinadns=chinadns-1.3.2
	cd $CACHE_DIR
	if [ ! -f ${chinadns}.tar.gz ]; then
		wget https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/${chinadns}.tar.gz
	fi
	tar xf ${chinadns}.tar.gz
	cd ${chinadns}
	./configure
	make && make install
}

