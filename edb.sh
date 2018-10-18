#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt cmake build-essential libboost-dev 
	check_apt libqt5xmlpatterns5-dev qtbase5-dev qt5-default libqt5svg5-dev 
	check_apt libgraphviz-dev
	check_apt libcapstone-dev pkg-config
	check_apt yasm nasm
	check_apt gdbserver

	setup_objconv

	cd $CACHE_DIR
	if [ ! -d edb-debugger ]; then
		git clone --recursive https://github.com/eteran/edb-debugger.git
	fi

	cd edb-debugger
	mkdir build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local/ ..
	make
	make install

	edb
}

maintain()
{
	cmd_exists_exit edb "Please execute edb"
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
