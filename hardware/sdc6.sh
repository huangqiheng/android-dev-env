#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo

	make_cmdline sdc6 <<-EOF
	#!/bin/dash
	sudo umount /data > /dev/null 2>&1
	sudo mount /dev/sdc6 /data
EOF
}

main "$@"; exit $?
