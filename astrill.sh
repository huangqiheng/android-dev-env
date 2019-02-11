#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt language-pack-zh-hans
	check_apt libgtk2.0-0

	cloudinit_remove
	auto_login
	auto_startx

	check_update universe
	check_apt xinit ratpoison 

	install_astrill
	check_apt xvfb
	ratpoisonrc "exec Xvfb :1 -screen 0 1920x1080x24 -fbdir /var/tmp &"
	ratpoisonrc "exec DISPLAY=:1 /usr/local/Astrill/astrill"
	setup_socat 3213 3128

	# others, for test
	ratpoisonrc_done
	check_apt proxychains 
	x11_forward_server
	help_text
	apt autoremove
}

setup_socat()
{
	localport=$1
	openport=$2

	check_apt socat 
	ratpoisonrc "exec socat tcp-listen:${openport},reuseaddr,fork tcp:localhost:${localport} &"
}

x11_forward_server()
{
	log_g 'setting ssh server'
	check_update_once
	check_apt xauth

	set_conf /etc/ssh/sshd_config
	set_conf X11Forwarding yes ' '
	set_conf X11DisplayOffset 10 ' '
	set_conf X11UseLocalhost no ' '

	cat /var/run/sshd.pid | xargs kill -1
}


help_text()
{
	cat << EOL
  astrill: 0.0.0.0:3128
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


