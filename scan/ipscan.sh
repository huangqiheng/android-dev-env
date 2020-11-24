#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	if cmd_exists ipscan; then
		ipscan
		return
	fi

	check_sudo

	cd $CACHE_DIR
	if [ ! -f ipscan_3.6.2_amd64.deb ]; then
		wget https://github.com/angryip/ipscan/releases/download/3.6.2/ipscan_3.6.2_amd64.deb
	fi

	dpkg -i ipscan_3.6.2_amd64.deb
}

main "$@"; exit $?
