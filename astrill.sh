#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	cloudinit_remove
	auto_login
	auto_startx

	check_update universe
	check_apt xinit ratpoison 

	install_astrill
	check_apt xvfb
	ratpoisonrc "exec Xvfb :1 -screen 0 1920x1080x24 -fbdir /var/tmp &"
	ratpoisonrc "exec DISPLAY=:1 /usr/local/Astrill/astrill"

	# others, for test
	ratpoisonrc_done
	check_apt proxychains 
	x11_forward_server
	help_text
	apt autoremove
}

help_text()
{
	cat << EOL
  astrill: 0.0.0.0:3128
  ssocks:  0.0.0.0:7070
  tor:     0.0.0.0:9050
  http:    0.0.0.0:8213
EOL
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	help_text
	exit 0
}
maintain "$@"; main "$@"; exit $?


