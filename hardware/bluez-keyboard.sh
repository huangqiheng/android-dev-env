#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

main () 
{
	check_update
	check_apt bluez		
	check_service bluetooth

	cat << EOL
bluetoothctl executes:
  power on
  agent KeyboardOnly
  default-agent
  pairable on
  scan on
  pair xx:xx:xx:xx:xx:xx
  trust xx:xx:xx:xx:xx:xx
  connect xx:xx:xx:xx:xx:xx
  quit
EOL
	bluetoothctl
}

#---------------------------------------------------------------------------------#
main_entry $@
