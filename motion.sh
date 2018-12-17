#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

IMGS_DIR=$UHOME/motion-pics

main () 
{
	check_sudo

	if cmd_exists "motion"; then
		motion
		log 'motion is running'
		exit 0
	fi

	check_update
	check_apt motion

	devPath="$1"
	if [ "$devPath" = ''  ]; then
		devPath='/dev/video0'
	fi

	imgSize=$(ffmpeg -f video4linux2 -hide_banner -list_formats all -i "$devPath" 2>&1 | grep mjpeg | awk -F: '{print $4}' | awk '{print $NF}')
	IFS=x; set -- $imgSize
	width=$1
	height=$2

	mkdir -p $IMGS_DIR

	set_conf /etc/motion/motion.conf
	set_conf width $width ' '
	set_conf height $height ' '
	set_conf target_dir $IMGS_DIR ' '

	set_conf output_pictures on ' '
	set_conf ffmpeg_output_movies off ' '

	motion
	log 'motion is running now'
}

maintain()
{
	[ "$1" = 'clean' ] && clean_exit
	[ "$1" = 'pack' ] && pack_exit $2
	[ "$1" = 'kill' ] && pkill_exit
	[ "$1" = 'help' ] && show_help_exit
}

clean_exit()
{
	cd $IMGS_DIR
	rm -f *.jpg
	exit
}

pack_exit()
{
	inputFiles="$IMGS_DIR/%*.jpg"
	timestamp=$(date -d "today" +"%Y%m%d%H%M")
	outputFile="$IMGS_DIR/pack-$timestamp.mp4"

	unlink $outputFile

	ffmpeg -r 60 -f image2 -i "$inputFiles" -vcodec libx264 -crf 25  -pix_fmt yuv420p $outputFile
	exit 0
}

pkill_exit()
{
	pkill -9 motion
	log 'killing motion'
	exit 0
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
