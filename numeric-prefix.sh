#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo
	make_cmdline nprefix <<-EOF
	matchRule="\${1:-*}"
	counter=0;

	ifsTab=\$(echo "\t")
	IFS=\$(echo "\n\r")
	for inputFile in \$(find . -maxdepth 1 -type f -name "\$matchRule" -printf "%T+\t%p\n" | sort); do
		counter=\$((\$counter + 1))
		IFS=\$ifsTab; set -- \$(echo "\$inputFile")
		baseFile=\$(basename "\$2")
		leader=\$(echo "\$baseFile" | grep -Eo '^[0-9]*-')

		if [ ! "X\$leader" = 'X' ]; then
			newFile=\$(echo "\$baseFile" | cut -c \$((\${#leader}+1))-)
			newFile="\$counter-\$newFile"
		else
			newFile="\$counter-\$baseFile"
		fi

		if [ ! "\$baseFile" = "\$newFile" ]; then
			mv "\$baseFile" "\$newFile"
			echo "\$newFile"
		fi
	done
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
