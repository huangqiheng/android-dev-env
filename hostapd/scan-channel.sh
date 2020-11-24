#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

IFACE="${IFACE:-wlan0}"

main()
{
	check_sudo
	iwlist "$IFACE" scan | grep Frequency | sort | uniq -c | sort -n
}

main "$@"; exit $?
