#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

x11_forward_client()
{
	log_g 'setting ssh client'
	cat > $UHOME/.ssh/config <<EOL
Host *
  ForwardAgent yes
  ForwardX11 yes
EOL
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


main () 
{
	num_param=$#
	if [ $num_param -eq 0 ]; then
		x11_forward_server
		exit 0
	fi

	if [ "$1" = 'client' ]; then
		x11_forward_client
		return 0
	fi

	ssh_target=$1
	ssh_opt="$2"
	IFS='@'; set -- "$1"
	hostName=$2

	if ping -c 1 "$hostName" &> /dev/null; then
		x11_forward_client
		ssh -v -X "$ssh_target" "$ssh_opt"
		exit 0
	fi

	exit 1
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
