#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_image 'rastasheep/ubuntu-sshd'

}

inside_docker_exit()
{
	nocmd_udpate astrill
	x11_forward_server
	install_astrill
	astrill
	exit 0
}

maintain()
{
	[ "$1" = 'inside' ] && inside_docker_exit
}

maintain "$@"; main "$@"; exit $?


