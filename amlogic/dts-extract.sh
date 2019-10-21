#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	check_apt device-tree-compiler

	make_cmdline dts-extract <<-EOF
	#!/bin/bash
	[ "X\$1" = 'X' ] && echo 'Need dtb file' && exit 1
	[ \${1##*.} != "dtb" ] && echo 'Need .dtb file' && exit 2

	fullname=\$(readlink -f \$1)
	outname="\${fullname%.dtb}".dts
	dtc -I dtb -O dts -o \$outname \$fullname
EOF
}

main "$@"; exit $?

