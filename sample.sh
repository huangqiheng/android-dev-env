#!/bin/dash

. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#. $(f='basic_mini.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)

main () 
{
}

init()
{
	check_update
}

help()
{
	cat << EOL

EOL
	exit 0
}


main_entry $@
