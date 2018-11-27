#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_apt cpanminus

	chownUser "$HOME/.cpanm"
	
	cpanm Net::Whois::IP
	cpanm Net::IP 
	cpanm Net::DNS
	cpanm Net::Netmask
	cpanm XML::Writer
	cpanm String::Random

	wget -O /usr/bin/dnsenum https://raw.githubusercontent.com/fwaeytens/dnsenum/master/dnsenum.pl
	chmod 755 /usr/bin/dnsenum
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
