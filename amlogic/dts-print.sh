#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_apt device-tree-compiler

	make_cmdline dts-print <<-EOF
	#!/bin/bash
	[ "X\$1" = 'X' ] && echo 'Need dtb file' && exit 1
	[ \${1##*.} != "dtb" ] && echo 'Need .dtb file' && exit 2
	dtc -I dtb -O dts $1
EOF
}

main "$@"; exit $?
