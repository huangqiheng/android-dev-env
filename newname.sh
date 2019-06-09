#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo

	make_cmdline newest <<-EOF
	#!/bin/dash

	toName="\$1"

	if [ "X\$toName" = 'X' ]; then
		echo 'please set output file name'
		exit 1
	fi

	lastNumber="\$2"

	if [ "X\$lastNumber" = 'X' ]; then
		lastNumber="1"
	fi

	fromName=\$(ls -1rt | tail --lines="\$lastNumber" | head -1)

	cd \$PWD

	if [ ! -f "\$fromName" ]; then
		echo "fine not exists: \$fromName"
		exit 1
	fi

	mv "\$fromName" "\$toName" 
EOF
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
