#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt python-pip
	pip install Pygments --upgrade
	
	make_cmdline ccat <<-EOF
	#!/bin/bash
	inFile="\${@: -1}"
	if [ "X\$inFile" = 'X' ]; then
		echo 'Need target file'
		exit 1
	fi
	if [ ! -f "\$inFile" ]; then
		echo 'Target file not exists'
		exit 2
	fi
	pygmentize -g -O style=colorful,linenos=1 \$*
EOF
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
