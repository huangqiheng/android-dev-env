#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_sudo 

	if [ "X$1" = 'X' ]; then
		log_r 'input error'
		exit 1
	fi

	if [ "$1" = 'remove' ]; then
		unlink /etc/apt/apt.conf.d/proxy.conf 2>/dev/null
		log_g 'remove proxy successfully'
		exit 0
	fi

	local proxy="$1"
	if echo "$1" | grep -v ':' >/dev/null; then
		if [ "X$2" = 'X' ]; then
			log_r 'Port is needed'
			exit 1
		fi
		proxy="$1:$2"
	fi

	if curl -x "http://${proxy}/" icanhazip.com >/dev/null; then
		echo "Acquire::http::Proxy \"http://${proxy}/\";" | cat > /etc/apt/apt.conf.d/proxy.conf
		exit 0
	fi

	if curl -x "socks://${proxy}/" icanhazip.com >/dev/null; then
		echo "Acquire::socks::Proxy \"socks5://${proxy}/\";" | cat > /etc/apt/apt.conf.d/proxy.conf
		exit 0
	fi

	log_y 'the input is invalid'
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
