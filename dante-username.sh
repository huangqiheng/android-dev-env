#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

LISTEN_PORT=2018

main () 
{
	[ "$1" = "add" ] && add_newuser_exit $2 $3
	[ "$1" = "del" ] && del_user_exit $2
	[ "$1" = "start" ] && dante_start_exit
	[ "$1" = "stop" ] && dante_stop_exit

	install_dante $1 $2
}

dante_start_exit()
{
	service restart danted
	exit 0
}

dante_stop_exit()
{
	service stop danted
	exit 0
}

del_user_exit()
{
	local user=$1
	passwd --delete $user
	userdel $user
	exit 0
}

add_newuser_exit()
{
	local user=$1
	local pass=$2
	useradd -s /sbin/nologin $user
	echo "$user:$pass" | chpasswd
	exit 0
}

install_dante()
{
	iface=$1
	external=$2

	if  [ -z $iface ] || [ -z $external ]; then
		echo "Usage:"
		echo "    bash date-username.sh eth0 239.21.233.41"
		exit 1
	fi

	check_update
	check_apt dante-server

	cat >/etc/danted.conf <<EOL
logoutput: syslog
internal: $iface port = $LISTEN_PORT
external: $external
clientmethod: none
socksmethod: username 
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody

client pass {
	from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
	log: connect disconnect error
}

socks pass {
	from: 0.0.0.0/0 to: 0.0.0.0/0
	protocol: tcp udp
	socksmethod: username 
}
EOL

	systemctl restart danted
}

main "$@"; exit $?
