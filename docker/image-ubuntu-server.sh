#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	build_image ubuntu-server <<-EOL
	FROM ubuntu:18.04
	ENV DEBIAN_FRONTEND noninteractive
	RUN apt-get update && apt-get install -y ubuntu-server
EOL
	image_exists ubuntu-server && log_y "image is ready"
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
