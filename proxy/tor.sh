#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main () 
{
	check_update ppa:webupd8team/tor-browser
	check_apt tor-browser
}

#---------------------------------------------------------------------------------#
main_entry $@
