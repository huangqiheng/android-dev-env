#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	cd $ROOT_DIR/proxy
	sh astrill-docker.sh 8000 &
	sh astrill-docker.sh 8001 &
	sh astrill-docker.sh 8002 &
	sh astrill-docker.sh 8003 &
	sh astrill-docker.sh 8004 
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
