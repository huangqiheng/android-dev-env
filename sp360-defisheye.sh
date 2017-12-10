#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
check_bash $@

main () 
{
	if ! cmd_exists ffmpeg; then
		check_apt ffmpeg 
	fi

	if [ "$1" = "" ]; then
		echo "Usage: "
		echo "  sh sp369_defish.sh /path/to/fileOrDir crop"
		echo "  sh sp369_defish.sh /path/to/fileOrDir defish"
		echo "  sh sp369_defish.sh /path/to/fileOrDir"
		return
	fi

	case "$2" in
	    "crop")
		if [ -f $1 ]; then
			crop_3div4 $1
		else
			for input_file in $(find $1 -type f -iname "*.mp4"); do
				crop_3div4 $input_file
			done
		fi
	    ;;

	    "defish")
		if [ -f $1 ]; then
			defisheye $1
		else
			for input_file in $(find $1 -type f -iname "*.mp4"); do
				defisheye $input_file
			done
		fi
	    ;;

	    *)
		if [ -f $1 ]; then
			crop_defisheye $1
		else
			for input_file in $(find $1 -type f -iname "*.mp4"); do
				crop_defisheye $input_file
			done
		fi
	    ;;
	esac
}

crop_defisheye()
{
	local output_file=$(get_output_name $1 "defish_crop")

	echo "defisheye crop: $1 >> $output_file"
	ffmpeg -hide_banner -loglevel panic -i $1 -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.20:k2=-0.20,crop=in_w:in_w*9/16" -vcodec h264 $output_file
}

defisheye()
{
	local output_file=$(get_output_name $1 "defish")

	echo "defisheye: $1 >> $output_file"
	ffmpeg -hide_banner -loglevel panic -i $1 -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.20:k2=-0.20" -vcodec h264 $output_file
}

crop_3div4()
{
	local output_file=$(get_output_name $1 "crop")
	echo "crop: $1 >> $output_file"
	ffmpeg -hide_banner -i $1 -vf "crop=in_w:in_w*9/16" -vcodec h264 $output_file
}

get_output_name()
{
	local input_file=$1
	local mark_str=$2

	local output_file=${input_file/%.mp4/_$mark_str.mp4}

	if [ "$input_file" = "$output_file" ]; then
		output_file=${input_file/%.MP4/_$mark_str.mp4}
	fi

	if [ "$input_file" = "$output_file" ]; then
		echo $input_file
		return
	fi

	if [ -f $output_file ]; then
		unlink $output_file
	fi

	echo $output_file
}


main "$@"; exit $?

