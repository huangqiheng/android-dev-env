#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	if [ ! -f "$1" ]; then
		log_r 'please input iso file'
		exit 1
	fi

	if ! ls -l "$2" | grep '^b'; then
		log_r 'please input device path'
		exit 1
	fi

	check_apt syslinux-utils

	cp "$1" /tmp/isohybrid.iso
	isohybrid /tmp/isohybrid.iso
	dd if=/tmp/isohybrid.iso of="$2" bs=8M
}

maintain()
{
	check_sudo
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL
	sudo iso2hybrid.sh /path/to/image.iso /dev/sdb

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
