#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	# /dev/sda3       /share   ext4    defaults        0       0

	src_dev="$1"
	dst_dir="$2"

	mkdir -p $dst_dir

	if [ ! -d "$dst_dir" ]; then
		log_y 'target dir is invalid'
		exit 1
	fi

	target_str="$src_dev  $dst_dir  ext4 defaults  0  0"
	if ! grep -q "$target_str" /etc/fstab; then
		echo $target_str >> /etc/fstab  
	fi

	log_y 'Please reboot to take effect'
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
