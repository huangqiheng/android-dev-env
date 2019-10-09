#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_sudo
	check_apt util-linux procps hostapd iproute2 iw haveged dnsmasq iptables
	bash create-ap.sh --config config.conf
}

main "$@"; exit $?
