#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh

main () 
{
	make_cmdline dts-print <<-EOF
	#!/bin/bash
	dtc -I dtb -O dts \$1
EOF

	empty_exit "$1" 'need dtb file'
	check_sudo
	dtc -I dtb -O dts $1

}

main "$@"; exit $?
