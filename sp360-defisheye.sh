#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh
check_bash $@

main () 
{
	if ! cmd_exists ffmpeg; then
		check_apt ffmpeg 
	fi

	if [ "$2" = "crop" ]; then
		for input_file in $(find $1 -type f -name "*defish.mp4"); do
			crop_3div4 $input_file
		done
		return 0
	fi

	if [ "$2" = "defisheye" ]; then
		if [ -f $1 ]; then
			transcode $1
		else
			for input_file in $(find $1 -type f -name "*.mp4"); do
				transcode $input_file
			done
		fi
		return 0
	fi

	return 0

	if [ -f $1 ]; then
		transcode $1
	else
		for input_file in $(find $1 -type f -name "*.defish.mp4"); do
			crop_3div4 $input_file
		done
	fi
}

crop_3div4()
{
	local input_file=$1
	local output_file=${input_file/%.mp4/_crop.mp4}

	if [ "$input_file" = "$output_file" ]; then
		output_file=${input_file/%.MP4/_crop.mp4}
	fi

	if [ "$input_file" = "$output_file" ]; then
		echo "It's not mp4 filename"
		return 1
	fi

	echo "transcode: $1 >> $output_file"

	if [ -f $output_file ]; then
		unlink $output_file
	fi

	ffmpeg -i $input_file -vf "crop=in_w:in_w*3/4" -c:a copy $output_file
}

defisheye()
{
	local input_file=$1
	local output_file=${input_file/%.mp4/_defish.mp4}

	if [ "$input_file" = "$output_file" ]; then
		output_file=${input_file/%.MP4/_defish.mp4}
	fi

	if [ "$input_file" = "$output_file" ]; then
		echo "It's not mp4 filename"
		return 1
	fi

	echo "transcode: $1 >> $output_file"

	if [ -f $output_file ]; then
		unlink $output_file
	fi

	# ffmpeg -i $input_file -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.20:k2=-0.20,crop=in_w/3*2:in_h/3*2" -c:a copy $output_file
	ffmpeg -hide_banner -loglevel panic -i $input_file -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.20:k2=-0.20" -c:a copy $output_file
}

main "$@"; exit $?

