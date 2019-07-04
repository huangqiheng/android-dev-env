#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

# https://developers.cloudflare.com/argo-tunnel/downloads/

main () 
{
	if [ "X$1" != 'Xf' ]; then
		if cmd_exists cloudflared; then
			log_y 'cloudflared is ready'
			exit 0
		fi
	fi

	check_sudo
	nocmd_update cloudflared

	local fileName="cloudflared-stable-linux-$(dpkg --print-architecture).deb"
	local url="https://bin.equinox.io/c/VdrWdbjqyF/${fileName}"

	echo URL=$url

	cd $CACHE_DIR
	if [ ! -f "$fileName" ]; then
		wget $url
	fi

	dpkg -i "$fileName"

	if ! pidof cloudflared; then
		cloudflared proxy-dns
	fi
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
