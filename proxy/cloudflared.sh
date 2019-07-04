#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

# https://developers.cloudflare.com/argo-tunnel/downloads/

main () 
{
	if cmd_exists cloudflared; then
		log_y 'cloudflared is ready'
		exit 0
	fi

	check_update

	loca fileName="cloudflared-stable-linux-$(dpkg --print-architecture).deb"
	local url="https://bin.equinox.io/c/VdrWdbjqyF/${fileName}"

	cd $CACHE_DIR
	if [ ! -f "$fileName" ]; then
		wget $url
	fi

	dpkg -i "$fileName"
}

maintain()
{
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
