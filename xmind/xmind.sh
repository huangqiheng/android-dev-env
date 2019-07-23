#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_sudo
	cd $DATA_DIR

	if [ ! -f xmind-8-beta-linux_amd64.deb ]; then
		wget http://www.xmind.net/xmind/downloads/xmind-8-beta-linux_amd64.deb
	fi

	rm $HOME/configuration -rf
	dpkg -i xmind-8-beta-linux_amd64.deb

	log_y 'just try xmind to run'
}

main "$@"; exit $?
