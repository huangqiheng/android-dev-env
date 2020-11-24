#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	cd $CACHE_DIR

	if [ ! -f ubuntu-18.04.3-desktop-amd64.iso ]; then
		wget http://mirrors.neusoft.edu.cn/ubuntu-releases/18.04.3/ubuntu-18.04.3-desktop-amd64.iso
	fi

	log_y "$CACHE_DIR/ubuntu-18.04.3-desktop-amd64.iso is ready"
}

main "$@"; exit $?
