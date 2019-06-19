#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	nocmd_udpate astrill
	x11_forward_server
	install_astrill
	astrill
}

main "$@"; exit $?


