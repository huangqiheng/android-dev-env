#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	# get extra package
	check_apt linux-firmware

	# Realtek rtl8812au
	check_apt rtl8812au-dkms
	
	# Ralink Technology, Corp. MT7601U Wireless Adapter
	build_mt7601u


}

build_mt7601u()
{
	# https://askubuntu.com/questions/457061/ralink-mt7601u-148f7601-wi-fi-adapter-installation

	check_apt linux-headers-generic build-essential git

	cd $CACHE_DIR
	git clone https://github.com/art567/mt7601usta.git
	cd mt7601usta/src 
	make
	make install
	mkdir -p /etc/Wireless/RT2870STA/
	cp RT2870STA.dat /etc/Wireless/RT2870STA/
	modprobe mt7601Usta
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
