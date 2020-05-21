#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main() 
{
	node_init commander
	node_exec main.js
}

#---------------------------------------------------------------------------------#
main_entry $@
