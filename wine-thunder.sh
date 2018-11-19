#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	check_apt wine-stable

	if [ ! -d $RUN_DIR/wine-thunder-for-linux ]; then
		cd $DATA_DIR
		tar xzvf wine-thunder-for-linux.tar.gz -C $RUN_DIR
	fi

	cd $RUN_DIR/wine-thunder-for-linux
	runUser 'wine Thunder.exe'
}

install_wine()
{
	wget -nc https://dl.winehq.org/wine-builds/Release.key
	apt-key add Release.key
	apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/
	check_update f
	apt-get install --install-recommends winehq-stable
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
