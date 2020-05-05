#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	nocmd_udpate aws
	check_apt awscli

}


#---------------------------------------------------------------------------------#
main_entry $@
