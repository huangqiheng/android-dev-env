#!/bin/dash

. $(dirname $(dirname $(readlink -f $0)))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	if [ "$1" = 'server' ]; then
		nc -dkl 1500 | mplayer -vo x11 -cache 512 -
		exit 0
	fi

	if [ "$1" = 'client' ]; then
		ffmpeg -f x11grab -video_size cif -framerate 25 -i :0.0+10,20 -f avi - | nc 127.0.0.1 1500
		exit 0
	fi

}

maintain()
{
	nocmd_udpate ffmpeg mplayer
	check_apt ffmpeg mplayer

	[ "$1" = 'help' ] && show_help_exit
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}

maintain "$@"; main "$@"; exit $?
