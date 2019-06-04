#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	if cmd_exists grub-customizer; then
		grub-customizer
		exit 0
	fi

	check_apt cmake gettext
	select_apt g++ gcc-c++
	select_apt libgtkmm-3.0-dev gtkmm30-devel libgtkmm-2.4-dev gtkmm24-devel
	select_apt libssl-dev openssl-devel
	select_apt libarchive-dev libarchive-devel	

	cd $CACHE_DIR
	if [ ! -f grub-customizer_5.1.0.tar.gz ]; then
		rm -rf grub-customizer-5.1.0
		wget https://launchpad.net/grub-customizer/5.1/5.1.0/+download/grub-customizer_5.1.0.tar.gz
	fi

	if [ ! -d grub-customizer-5.1.0 ]; then
		tar xzvf grub-customizer_5.1.0.tar.gz
	fi

	cd grub-customizer-5.1.0
	cmake .
	make
	make install
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
