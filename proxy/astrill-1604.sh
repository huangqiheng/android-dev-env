#!/bin/bash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	login_root_exec startx

	check_update universe
	check_apt xinit ratpoison 

	# install astrill
	install_astrill
	setup_socat 3213 3128
	setup_polipo 7070 8213

	# install tor
	setup_tor '127.0.0.1:7070'

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
  http:    0.0.0.0:8213
EOL
}

setup_socat()
{
	localport=$1
	openport=$2

	check_apt socat 
	ratpoisonrc "exec socat tcp-listen:${openport},reuseaddr,fork tcp:localhost:${localport} &"
}

fix_gpt_auto_error()
{
	set_conf /etc/default/grub
	set_conf GRUB_CMDLINE_LINUX_DEFAULT '"systemd.gpt_auto=0"'
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


