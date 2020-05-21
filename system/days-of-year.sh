#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	if [ "X$1" = 'X' ]; then
		date +%j
	else
		date -d "$1" +%j
	fi

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
