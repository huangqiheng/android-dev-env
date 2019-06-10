#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	check_apt bridge-utils

	if [ $# -lt 2 ]; then
		log_r 'at lease two parameters'
		exit 1
	fi

	firstIface="$1"; shift
	log_y "first interface: $firstIface; others: $@"

	if brctl show "$firstIface" 2>&1 >/dev/null; then
		log_y "first interface is bridge"
		brname="$firstIface"
		brctl addif $brname $@
	else
		brname=$(get_br_name)
		log_y "making bridge $brname"
		brctl addbr $brname
		brctl addif $brname $@
	fi
}

get_br_name()
{
	local index=0
	for num in 0 1 2 3 4 5 6 7 8 9; do
		brname="br${num}"
		brctl show $brname >/dev/null 2>&1 
		if [ "$?" = '1' ]; then
			echo $brname
			return
		fi
	done
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
