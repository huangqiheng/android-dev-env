#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt nfs-kernel-server

	cat << EOL
please add directories to exports:
	sh nfs.sh add /path/to/export
EOL
}

maintain()
{
	check_update
	[ "$1" = 'add' ] && add_exports_exit $2
}

add_exports_exit()
{
	echo "$1    *(ro,sync,no_root_squash)" >> /etc/exports
	systemctl restart nfs-kernel-server.service
}

maintain "$@"; main "$@"; exit $?
