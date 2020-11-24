#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	image_path="$1"
	if [ ! -d $image_path ]; then
		image_path=$(pwd)
	fi
	image_path="$image_path/%*.jpg"

	ffmpeg -r 60 -f image2 -s 1280x720 -i "$image_path" -vcodec libx264 -crf 25  -pix_fmt yuv420p new.mp4

	rm $image_path
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
