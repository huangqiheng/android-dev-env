#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_update f
	check_apt xinit ratpoison 

	set_conf /etc/systemd/system/getty.target.wants/getty@tty1.service
	set_conf ExecStart "-/sbin/agetty --autologin ${RUN_USER}--noclear %I \$TERM"

	install_astrill
	check_apt socat shadowsocks proxychains

	ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
	ratpoisonrc "exec socat tcp-listen:3128,reuseaddr,fork tcp:localhost:3213 &"
	ratpoisonrc "exec /usr/local/Astrill/astrill"
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?


