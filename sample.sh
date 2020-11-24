#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
}

init()
{
	nocmd_update test
}

help()
{
	cat << EOL
EOL
	exit 0
}

#---------------------------------------------------------------------------------#
main_entry $@
