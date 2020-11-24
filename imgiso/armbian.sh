#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
#. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	cd $CACHE_DIR
	https://yadi.sk/d/5_32km_EsCV2A/ARMBIAN/5.90/s9xxx/default
	unxz Armbian_5.76_Aml-s912_Ubuntu_bionic_default_5.0.0-gf2f3a8c1a-dirty_20190313.img
	mkusb-nox 
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
