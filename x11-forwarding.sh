#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ "$1" = 'client' ];then
		log 'setting ssh client'
		x11_forward_client
		exit
	fi

	log 'setting ssh server'
	x11_forward_server
}

x11_forward_server()
{
	check_apt xauth

	set_conf /etc/ssh/sshd_config
	set_conf X11Forwarding yes ' '
	set_conf X11DisplayOffset 10 ' '
	set_conf X11UseLocalhost no ' '

	cat /var/run/sshd.pid | xargs kill -1
}

x11_forward_client()
{
	cat > $HOME/.ssh/config <<EOL
Host *
  ForwardAgent yes
  ForwardX11 yes
EOL
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
