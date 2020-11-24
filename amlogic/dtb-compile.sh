#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_apt device-tree-compiler

	make_cmdline dtb-compile <<-EOF
	#!/bin/bash
	[ "X\$1" = 'X' ] && echo 'Need dts file' && exit 1
	[ \${1##*.} != "dts" ] && echo 'Need .dts file' && exit 2

	fullname=\$(readlink -f \$1)
	outname="\${fullname%.dts}".dtb
	dtc -I dts -O dtb -o \$outname \$fullname
EOF
}

main "$@"; exit $?
