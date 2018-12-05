#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if [ -z $1 ]; then
		log_red 'input error'
		exit 1
	fi

	if [ "$1" = 'remove' ]; then
		unlink /etc/apt/apt.conf.d/proxy.conf 2>/dev/null
		log_green 'remove proxy successfully'
		exit 0
	fi


	echo "Acquire::http::Proxy \"http://${1}/\";" | cat > /etc/apt/apt.conf.d/proxy.conf
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
