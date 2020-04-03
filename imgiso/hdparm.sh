#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main () 
{
	check_apt hdparm

	cat <<EOL
	hdparm -I /dev/sda
	hdparm --user-master u --security-set-pass llformat /dev/sda
	hdparm --user-master u --security-erase llformat /dev/sda

	dd if=/dev/zero of=/dev/XXXXXX bs=512 count=1
EOL
}

#---------------------------------------------------------------------------------#
main_entry $@
