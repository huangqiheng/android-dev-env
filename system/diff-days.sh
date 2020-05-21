#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	check_apt dateutils

	empty_exit "$1" 'backward day'
	empty_exit "$2" 'forward day'

	dateutils.ddiff $1 $2
}

help()
{
	cat << EOL
	sh $EXEC_NAME "2020-02-23"
EOL
	exit 0
}

#---------------------------------------------------------------------------------#
main_entry $@
