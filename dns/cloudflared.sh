#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#--------------------------------------------------------------------------------#

# https://developers.cloudflare.com/argo-tunnel/downloads/
main () 
{
	if [ "X$1" != 'Xf' ]; then
		if cmd_exists cloudflared; then
			log_y 'cloudflared is ready'
			run
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

	run
}

run()
{
	if ! pidof cloudflared; then
		echo "nameserver 127.0.0.1" > /etc/resolv.conf
		cloudflared proxy-dns
	fi
}

#---------------------------------------------------------------------------------#
main_entry $@
