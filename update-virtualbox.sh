#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	apt remove virtualbox --auto-remove
	wget -q -O - https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo apt-key add - echo deb http://download.virtualbox.org/virtualbox/debian `lsb_release -cs` non-free contrib | sudo tee /etc/apt/sources.list.d/virtualbox.org.list
	apt update
	apt install virtualbox-5.2
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat <<< EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
